module Pagination
  extend ActiveSupport::Concern

  MAX_PER_PAGE = 100
  DEFAULT_PER_PAGE = 20

  def paginate(scope, count_scope = scope)
    page = [params.fetch(:page, 1).to_i, 1].max
    per = params.fetch(:per, DEFAULT_PER_PAGE).to_i.clamp(1, MAX_PER_PAGE)
    total = count_scope.distinct.count

    records = scope.offset((page - 1) * per).limit(per)
    meta = {
      page: page,
      per: per,
      total: total,
      total_pages: (total / per.to_f).ceil
    }
    [records, meta]
  end
end
