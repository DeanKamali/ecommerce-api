module CouponSerializer
  def self.serialize(coupon)
    {
      id: coupon.id,
      code: coupon.code,
      kind: coupon.kind,
      value: coupon.value,
      min_subtotal_cents: coupon.min_subtotal_cents,
      valid_from: coupon.valid_from,
      valid_until: coupon.valid_until,
      max_redemptions: coupon.max_redemptions,
      used_count: coupon.used_count,
      active: coupon.active,
      redeemable: coupon.redeemable?,
      created_at: coupon.created_at
    }
  end
end
