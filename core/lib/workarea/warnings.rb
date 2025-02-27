module Workarea
  module Warnings
    extend self

    def check
      check_timezone
      check_mongo_notable_scan
      check_dragonfly_config
      check_auto_capture
    end

    def check_timezone
      if Rails.application.config.time_zone == 'UTC'
        warn <<~eos
**************************************************
⛔️ WARNING: Rails.application.config.time_zone is set to UTC, which you \
probably don't want.
As of Workarea 3.2, we use that value as the standard \
timezone for the admin side of the application.
We recommend setting this to the timezone of the retailer. Contact them to \
find their preference.
**************************************************
        eos
      end
    end

    def check_mongo_notable_scan
      if (Rails.env.development? &&
          !Workarea.config.skip_service_connections &&
          Configuration::Mongoid.indexes_enforced?)
        warn <<~eos
**************************************************
⛔️ WARNING: MongoDB is configured with notablescan.

This means that MongoDB won't run queries that require a collection scan and will return an error.
Workarea turns this on for running tests to assert that queries have indexes, and turns it off at the end of the test run.
Since you're not running in the test environment and this is turned on, it might mean the test process was killed, preventing Workarea from turning it off.

To turn this off, start the mongo shell and run this command:
db.getSiblingDB("admin").runCommand( { setParameter: 1, notablescan: 0 } )
**************************************************
        eos
      end
    end

    def check_dragonfly_config
      if !Rails.env.test? && !Rails.env.development? &&
           Dragonfly.app(:workarea).datastore.is_a?(Dragonfly::FileDataStore)

        warn <<~eos
**************************************************
⛔️ WARNING: Dragonfly is configured to use the filesystem.

This means all dragonfly assets (assets, product images, etc.) will be stored
locally and not accessible to all servers within your environment.

We recommend using S3 when running in a live environment by setting
WORKAREA_S3_REGION and WORKAREA_S3_BUCKET_NAME in your environment variables.
Workarea will automatically configure Dragonfly to use S3 if those values
are present.
**************************************************
        eos
      end
    end

    def check_auto_capture
      if Workarea.config.auto_capture
        warn <<~eos
**************************************************
⛔️ WARNING: Workarea is configured with Workarea.config.auto_capture.

In v3.5, this is being deprecated to allow more flexibility based on the types
of items in the order.

You should set Workarea.config.checkout_payment_action instead. You can set it
for each type of order, here are the defaults:
  {
    shipped: 'authorize!',
    not_shipped: 'purchase!',
    mixed: 'authorize!'
  }

To achieve the same functionality as Workarea.config.auto_capture, you'd set:
  {
    shipped: 'purchase!',
    not_shipped: 'purchase!',
    mixed: 'purchase!'
  }

**************************************************
        eos
      end
    end
  end
end
