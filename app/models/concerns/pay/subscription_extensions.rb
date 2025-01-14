module Pay
  module SubscriptionExtensions
    extend ActiveSupport::Concern

    included do
      after_commit :send_admin_notification
      after_commit :send_subscribed
    end

    def send_admin_notification
      Admin::SubscriptionChangeNotification.new(
        subscription: self,
        change: SubscriptionChanges.new(self).change
      ).deliver_later(User.admin)
    rescue Pay::SubscriptionChanges::UnknownSubscriptionChange => e
      Honeybadger.notify(e)
    end

    def send_subscribed
      return unless SubscriptionChanges.new(self).subscribed?

      business = customer.owner.business
      BusinessMailer.with(business:).subscribed.deliver_later
    rescue Pay::SubscriptionChanges::UnknownSubscriptionChange => e
      Honeybadger.notify(e)
    end
  end
end
