class ReportJob < ApplicationJob
  queue_as :default

  # period: "weekly" | "monthly" — the snapshot is (re)computed for the
  # calendar period containing now, so re-running is idempotent.
  def perform(period)
    Report.generate(period)
  end
end
