class Coupon < ApplicationRecord
  KINDS = %w[percent fixed].freeze

  # Raised when a coupon is known but not usable right now (inactive,
  # outside its validity window, redeemed out, or the cart doesn't meet the
  # minimum subtotal).
  class NotApplicable < StandardError; end

  before_validation do
    self.code = code.to_s.strip.upcase
    self.min_subtotal_cents = min_subtotal_cents.to_i.clamp(0, Float::INFINITY)
  end

  validates :code, presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: /\A[A-Z0-9][A-Z0-9_-]*\z/ }
  validates :kind, inclusion: { in: KINDS }
  validate :value_is_sane
  validates :min_subtotal_cents, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :max_redemptions, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :used_count, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :active, inclusion: { in: [true, false] }
  validate :valid_window_is_sane

  scope :active, -> { where(active: true) }

  # Redeemable in general (independent of any particular cart).
  def redeemable?(now = Time.current)
    active &&
      (valid_from.nil? || valid_from <= now) &&
      (valid_until.nil? || valid_until > now) &&
      (max_redemptions.nil? || used_count < max_redemptions)
  end

  def applies_to_subtotal?(subtotal_cents, now = Time.current)
    redeemable?(now) && subtotal_cents >= min_subtotal_cents
  end

  # Cents taken off `subtotal_cents` (0 when it doesn't apply).
  def discount_cents(subtotal_cents, now = Time.current)
    return 0 unless applies_to_subtotal?(subtotal_cents, now: now)

    case kind
    when "percent" then subtotal_cents * value / 100
    when "fixed" then [value, subtotal_cents].min
    end
  end

  # Attach to a cart and count one redemption. Raises NotApplicable if the
  # coupon can't be used on this cart right now. Re-applying the same coupon
  # is idempotent; replacing a different coupon releases its redemption.
  def apply_to!(cart, now = Time.current)
    unless redeemable?(now)
      raise NotApplicable, "coupon #{code} is not available right now"
    end
    if cart.subtotal_cents < min_subtotal_cents
      raise NotApplicable, "cart subtotal must be at least #{min_subtotal_cents} cents for #{code}"
    end

    previous = cart.applied_coupon
    cart.applied_coupon = self
    cart.save!
    if previous != self
      increment!(:used_count)
      previous&.decrement!(:used_count)
    end
    self
  end

  def value_is_sane
    case kind
    when "percent"
      errors.add(:value, "must be between 1 and 100") unless value.to_i.between?(1, 100)
    when "fixed"
      errors.add(:value, "must be a positive number of cents") unless value.to_i.positive?
    end
  end

  def valid_window_is_sane
    return if valid_from.nil? || valid_until.nil?

    errors.add(:valid_until, "must be after valid_from") if valid_until <= valid_from
  end
end
