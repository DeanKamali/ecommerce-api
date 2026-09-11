class Order < ApplicationRecord
  STATUSES = %w[pending confirmed shipped delivered cancelled].freeze

  TRANSITIONS = {
    "pending" => %w[confirmed cancelled],
    "confirmed" => %w[shipped cancelled],
    "shipped" => %w[delivered],
    "delivered" => [],
    "cancelled" => []
  }.freeze

  class InsufficientStock < StandardError; end

  has_many :order_items, dependent: :destroy
  belongs_to :user
  belongs_to :cart, optional: true

  validates :number, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :subtotal_cents, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :total_cents, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :currency, length: { is: 3 }, format: { with: /\A[A-Z]{3}\z/ }
  validates :customer_name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :has_items

  before_validation :set_defaults, on: :create

  # Create an order from explicit line items: [[catalog_item, variant, quantity], ...]
  def self.create_with_items!(items, attributes = {})
    if items.blank?
      order = new(attributes)
      order.errors.add(:order_items, "must include at least one item")
      raise ActiveRecord::RecordInvalid, order
    end

    transaction do
      order = new(attributes)
      items.each do |catalog_item, variant, quantity|
        ensure_sellable!(catalog_item, variant, quantity)
        order.order_items.build(
          catalog_item: catalog_item,
          variant: variant,
          name: catalog_item.name,
          variant_name: variant&.name,
          unit_price_cents: variant ? variant.price_cents : catalog_item.price_cents,
          quantity: quantity
        )
      end
      order.subtotal_cents = order.order_items.sum { |oi| oi.unit_price_cents * oi.quantity }
      order.total_cents = order.subtotal_cents
      order.save!
      decrement_stock!(items)
      order
    end
  end

  def can_transition_to?(new_status)
    TRANSITIONS.fetch(status, []).include?(new_status)
  end

  # Returns true on success; adds errors and returns false on an invalid transition.
  def transition_to(new_status)
    return false unless STATUSES.include?(new_status)
    return true if new_status == status

    unless can_transition_to?(new_status)
      errors.add(:status, "cannot transition from #{status} to #{new_status}")
      return false
    end

    update!(status: new_status)
  end

  # Cancellable from pending/confirmed; restocks sellable items.
  # Returns true on success; adds errors and returns false otherwise.
  def cancel!
    unless can_transition_to?("cancelled")
      errors.add(:status, "cannot cancel an order in the #{status} state")
      return false
    end

    transaction do
      update!(status: "cancelled")
      restock!
    end
    true
  end

  def restock!
    order_items.each do |oi|
      item = oi.catalog_item
      next unless item.is_a?(Product) && item.track_inventory?

      if oi.variant
        oi.variant.increment(:stock_quantity, oi.quantity)
      else
        item.increment(:stock_quantity, oi.quantity)
      end
    end
  end

  private

  def self.ensure_sellable!(catalog_item, variant, quantity)
    return unless catalog_item.is_a?(Product)
    return unless catalog_item.track_inventory?

    if catalog_item.variants.exists? && variant.nil?
      raise ActiveRecord::RecordInvalid.new(
        catalog_item.tap { |c| c.errors.add(:variants, "are required for this product") }
      )
    end

    stock = if variant
      variant.stock_quantity
    elsif catalog_item.variants.exists?
      catalog_item.variants.sum(:stock_quantity)
    else
      catalog_item.stock_quantity
    end

    raise InsufficientStock, "#{catalog_item.name}: only #{stock} in stock, requested #{quantity}" if stock < quantity
  end

  def self.decrement_stock!(items)
    items.each do |catalog_item, variant, quantity|
      next unless catalog_item.is_a?(Product)
      next unless catalog_item.track_inventory?

      if variant
        variant.decrement(:stock_quantity, quantity)
      elsif catalog_item.variants.exists?
        # Sold as a pool across variants; charge the first variant with stock.
        catalog_item.variants.order(stock_quantity: :desc).each do |v|
          take = [v.stock_quantity, quantity].min
          next if take.zero?

          v.decrement(:stock_quantity, take)
          quantity -= take
          break if quantity.zero?
        end
      else
        catalog_item.decrement(:stock_quantity, quantity)
      end
    end
  end

  def set_defaults
    self.number ||= format("ORD-%s-%s", Time.now.utc.strftime("%Y%m%d"), SecureRandom.hex(3).upcase)
    self.currency = currency.to_s.upcase.presence || "USD"
  end

  def has_items
    errors.add(:order_items, "must include at least one item") if new_record? && order_items.empty?
  end
end
