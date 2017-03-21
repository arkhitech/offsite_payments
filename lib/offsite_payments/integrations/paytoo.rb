module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Paytoo

      # Overwrite this if you want to change the PayFast sandbox url
      mattr_accessor :process_test_url
      self.process_test_url = 'https://go.paytoo.info/gateway'

      # Overwrite this if you want to change the PayFast production url
      mattr_accessor :process_production_url
      self.process_production_url = 'https://go.paytoo.com/gateway'

      # # Overwrite this if you want to change the PayFast sandbox url
      # mattr_accessor :validate_test_url
      # self.validate_test_url = 'https://sandbox.payfast.co.za/eng/query/validate'
      #
      # # Overwrite this if you want to change the PayFast production url
      # mattr_accessor :validate_production_url
      # self.validate_production_url = 'https://www.payfast.co.za/eng/query/validate'

      mattr_accessor :signature_parameter_name
      self.signature_parameter_name = 'hash'

      def self.service_url
        mode = OffsitePayments.mode
        case mode
        when :production
          self.process_production_url
        when :test
          self.process_test_url
        else
          raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      # def self.validate_service_url
      #   mode = OffsitePayments.mode
      #   case mode
      #   when :production
      #     self.validate_production_url
      #   when :test
      #     self.validate_test_url
      #   else
      #     raise StandardError, "Integration mode set to an invalid value: #{mode}"
      #   end
      # end

      def self.helper(order, account, options = {})
        Helper.new(order, account, options)
      end

      def self.notification(query_string, options = {})
        Notification.new(query_string, options)
      end

      def self.return(post, options = {})
        Return.new(post, options)
      end

      module Common
        def generate_signature(type)
          string = case type
          when :request
            request_signature_string
          when :notify
            notify_signature_string
          end

          Digest::MD5.hexdigest(string)
        end

        # Documentation:
        # <form action="https://go.paytoo.info/gateway" method="post">
        # <input type="hidden" name="merchant_id" value="12345678" />
        # <input type="hidden" name="amount" value="5.00" />
        # <input type="hidden" name="currency" value="USD" />
        # <input type="hidden" name="order_ref" value="1234" />
        # <input type="hidden" name="order_description" value="Order number 1234" />
        # <input type="image" name="submit" value="Pay with PayToo"
        # src="https://go.paytoo.info/files/paytoo/images/button/gateway/S1_1.png" />
        # </form>
        #
        #
        # 2.4 Parameters list
        # Below you can see an explanation of all the parameters that can be used for payment buttons:
        #      Parameter Name Required Description
        #      merchant_id YES Your 8 digits Go.PayToo Merchant ID
        #      amount YES The total amount requested
        #      currency YES The currency of the transaction (always the same currency as
        #      your Go.PayToo Merchant Account).
        #      order_ref YES A unique reference for this transaction
        #      order_description NO The transaction description (will be echo to the customer)
        #      sub_account_id NO An optional sub account ID to group your transactions
        #      hash NO Checksum of the request (see chapter 5)
        #      user[email] NO Customer’s email address
        #      user[firstname] NO Customer’s first name
        #      user[lastname] NO Customer’s last name
        #      user[address] NO Customer’s address
        #      user[zipcode] NO Customer’s postal code
        #      user[city] NO Customer’s city
        #      user[country] NO Customer’s country
        #      user[state] NO Customer’s state (for US resident only)
        #      user[cellphone] NO Customer’s cell phone (with international prefix)
        #      recurring[enabled] NO Enable recurring payment/subscription. Must be set to 'yes' in
        #      order to enable recurring payment.
        #      recurring[amount] NO The total amount requested for all recurring payments.
        #      recurring[cycles] NO Number of cycles/periods (>1 or 0 for unlimited)
        #      recurring[periodicity] NO Recurring period (weeks, months, years)
        #      recurring[start date] NO Date of the first transaction (format is YYYY-MM-DD)
        #      recurring[hash] NO Checksum of the recurring request (see chapter 5)
        #      completed_url NO The URL where the user will be redirected to after he
        #      completes the payment. On the last step of the payment there
        #      is a button labeled "Return" and when the user clicks this
        #      button he is redirected to this URL. If provided, this
        #      parameter override the value set in your settings (see chapter
        #      3.3).
        #          cancelled_url NO The URL where the user will be redirected to after he cancels
        #      the payment. On the cancel step of the payment there is a
        #      button labeled "Return" and when the user clicks this button
        #      he is redirected to this URL. If provided, this parameter
        #      override the value set in your settings (see chapter 3.3).
        #          GoPayToo – Payment Button Integration Guide 7
        #      Parameter Name Required Description
        #      rejected_url NO The URL where the user will be redirected to after the
        #      payment has been rejected. On the rejection page of the
        #      payment there is a button labeled "Return" and when the user
        #      clicks this button he is redirected to this URL. If provided,
        #      this parameter override the value set in your settings (see
        #      chapter 3.3).
        #          esign_url NO The URL where the user will be redirected to when his
        #      payment is pending for signature (see chapter 7.3). On the
        def request_attributes
          [:merchant_id, :amount, :currency, :order_ref,
           :order_description, :sub_account_id, :hash, 'user[email]',
           'user[firstname]', 'user[lastname]', 'user[address]', 'user[zipcode]',
           'user[city]', 'user[state]', 'user[cellphone]', 'recurring[enabled]',
           'recurring[amount]', 'recurring[cycles]', 'recurring[periodicity]',
           'recurring[start date]', 'recurring[hash]'
          ]
        end

        def request_signature_string
          request_attributes.map do |attr|
            "#{mappings[attr]}=#{CGI.escape(@fields[mappings[attr]])}" if @fields[mappings[attr]].present?
          end.compact.join('&')
        end

        def notify_signature_string
          params.map do |key, value|
            "#{key}=#{CGI.escape(value)}" unless key == Paytoo.signature_parameter_name
          end.compact.join('&')
        end
      end

      class Helper < OffsitePayments::Helper
        include Common


            def initialize(order, account, options = {})
          super
          add_field('merchant_id', account)
          add_field('order_ref', order)
          add_field('amount', 55)
          add_field('currency', 'USD')
          add_field('user[email]', 'test@test.com')
          add_field('user[firstname]', 'Ghias')
          add_field('user[lastname]', 'Arshad')
          add_field('user[phone_field1]', '111')
          add_field('user[phone_field2]', '222')
          add_field('user[phone_field3]', '3333')
          add_field('user[address]', '125 Maiden Lane, 11th Floor')
          add_field('user[zipcode]', '10000')
          add_field('user[city]', 'Test')
          add_field('hash', "#{ENV['PAYTOO_HASH']}")
          add_field('completed_url', 'https://www.locker81app.com/paytoo/success')
          add_field('cancelled_url', 'https://www.locker81app.com/paytoo/cancel')
          add_field('rejected_url', 'https://www.locker81app.com/paytoo/cancel')

            end

        def form_fields
          @fields
        end

        def params
          @fields
        end

        mapping :account, 'merchant_id'
        mapping :order, 'order_ref'
        mapping :amount, 'amount'
        mapping :currency, 'currency'
        mapping :first_name, 'user[firstname]'
        mapping :last_name, 'user[lastname]'
        mapping :email, 'user[email]'
        #mapping :cellphone, 'user[cellphone]'
        mapping :address, 'user[address]'
        mapping :country, 'user[country]'
        mapping :city, 'user[city]'
        mapping :state, 'user[state]'
        mapping :zip, 'user[zipcode]'
        mapping :cancel_return_url, 'cancelled_url'
        mapping :return_url, 'completed_url'
        mapping :country, 'user[country]'
        mapping :credential2, 'hash'



        #
        mapping :cellphone,

                :phone_field1   => 'user[phone_field1]',
                :phone_field2   => 'user[phone_field2]',
                :phone_field3   => 'user[phone_field3]'
      end




      # Parser and handler for incoming ITN from PayFast.
      # The Example shows a typical handler in a rails application.
      #
      # Example
      #
      #   class BackendController < ApplicationController
      #     include OffsitePayments::Integrations
      #
      #     def pay_fast_itn
      #       notify = PayFast::Notification.new(request.raw_post)
      #
      #       order = Order.find(notify.item_id)
      #
      #       if notify.acknowledge
      #         begin
      #
      #           if notify.complete? and order.total == notify.amount
      #             order.status = 'success'
      #
      #             shop.ship(order)
      #           else
      #             logger.error("Failed to verify Paypal's notification, please investigate")
      #           end
      #
      #         rescue => e
      #           order.status = 'failed'
      #           raise
      #         ensure
      #           order.save
      #         end
      #       end
      #
      #       render :nothing
      #     end
      #   end

      # 4.3 Data sent in the post back and the IPN
      # The data sent are the same in the post back and in the IPN.
      #     This data are sent in a POST array.
      #     In PHP, for example, you will access these data using $_POST[‘MerchantApiResponse’].
      #         For a better understanding, we can represent these data as an HTML form, like the one below.
      #             <form method="post">
      #             <input type="hidden" name="MerchantApiResponse[status]" value="OK">
      #     <input type="hidden" name="MerchantApiResponse[request_id]" value="11122">
      #     <input type="hidden" name="MerchantApiResponse[request_status]" value="completed">
      #     <input type="hidden" name="MerchantApiResponse[tr_id]" value="22782">
      #     <input type="hidden" name="MerchantApiResponse[sub_account_id]" value="8888">
      #     <input type="hidden" name="MerchantApiResponse[ref_id]" value="1234">
      #     <input type="hidden" name="MerchantApiResponse[msg]" value="">
      #     <input type="hidden" name="MerchantApiResponse[info]" value="">
      #     <input type="hidden" name="MerchantApiResponse[phone_number]" value="demo@paytoo.com">
      #     <input type="hidden" name="MerchantApiResponse[w_number]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][request_id]" value="11122">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][tr_id]" value="22782">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][user_id]" value="6095">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][ref_id]" value="1234">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][sub_account_id]" value="8888">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][date]" value="2014-03-27 13:19:35">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][refund_date]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][expiration]" value="2014-03-28 01:19:35">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][statement_id]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][refund_statement_id]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][method]" value="gateway">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][type]" value="small">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][is_pre_auth]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][is_recurring]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][is_a_cycle]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][recurring_id]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][currency]" value="USD">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][amount]" value="5.00">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][description]" value="Order number 1234">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][addinfo]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][status]" value="completed">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][status_infos]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][recurring_amount]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][recurring_cycles]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][recurring_period]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][recurring_start]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][recurring_end]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][recurring_status]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][recurring_info]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][transaction]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][card_present]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][employee_id]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][location_id]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][firstname]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][lastname]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooRequest][email]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_id]" value="22782">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_type]" value="wallet2merchant">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_from_type]" value="yackie">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_from_id]" value="01208100">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_from_currency]" value="USD">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_to_type]" value="merchant">
      #         GoPayToo – Payment Button Integration Guide 13
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_to_id]" value="12345678">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_to_currency]" value="USD">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_requested_original]" value="5.0000">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_requested_currency]" value="USD">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_amount_requested]" value="5.0000">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_amount_transfered]" value="5.0000">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_amount_total_cost]" value="5.0000">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_amount_refunded]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_change_rate]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_fees]" value="0.0000">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_fees_currency]" value="USD">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_fees_type]" value="fixed">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_fees_rate_fixed]" value="0.0000">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_fees_rate_percent]" value="0.0000">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_fees_level]" value="2">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_date_created]" value="2014-03-27 13:19:35">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_date_updated]" value="2014-03-27 13:19:42">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_date_completed]" value="2014-03-27 13:19:42">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_date_refunded]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_notif_sender]" value="email">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_notif_receiver]" value="none">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_status]" value="completed">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_status_msg]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooTransaction][pay_infos]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][user_id]" value="6095">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][wallet]" value="01208100">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][currency]" value="USD">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][registered_phone]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][max_pin]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][sim_phonenumber]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][prepaidcard]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][email]" value="demo@paytoo.com">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][gender]" value="m">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][firstname]" value="Cedric">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][middlename]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][lastname]" value="Mayol">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][address]" value="Some street ">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][city]" value="Fort Lauderdale">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][zipcode]" value="33301">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][country]" value="US">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][state]" value="FL">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][phone]" value="33679555985">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][level]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][question1]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][answer1]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][question2]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][answer2]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][question3]" value="">
      #     <input type="hidden" name="MerchantApiResponse[PaytooAccount][answer3]" value="">
      #     <input type="hidden" name="MerchantApiResponse[hash]" value="def2e614513fc7cf0d85c97167fb10ab">
      #     </form>
      #
      #
      # 4.4 MerchantApiResponse
      # Below are all the parameters of the post back and IPN explained
      # 4.4.1 Root data
      # Propertie Type Description
      # status string Has the value "OK" for successful, "PENDING" for pending
      # transaction or "ERROR" for failure
      #   request_id int Request ID is the unique ID of the request
      #   request_status string Request status, it can be 'pending', 'accepted', 'rejected',
      #                                                  'cancelled', 'completed', 'refunded'
      #   tr_id int Transaction ID is the unique ID of transaction associated to
      #   the request
      #   sub_account_id string Sub Account ID for which you have associated this request
      #                                         ref_id string Reference ID is the unique ID you've passed for this request
      #   msg string Message
      #   info string Additional information
      #   phone_number string * The phone number reserved for a micro payment in case of
      #   a Micropayment response
      #   * The customer registered phone number or simcard phone
      #   number in all other case
      #   w_number string Wallet number of the associated PayToo account
      #   PaytooTransaction PaytooTransactionType PayToo Transaction information associated to a
      #   request/transaction
      #   PaytooAccount PaytooAccountType PayToo Account information associated to a
      #   request/transaction
      #   PaytooRequest PaytooRequestType PayToo Request with full information
      #   hash string Hash code to check the authenticity of the IPN response – not
      #   filled with the API
      class Notification < OffsitePayments::Notification
        include ActiveUtils::PostsData
        include Common

        # Was the transaction complete?
        def complete?
          #     <input type="hidden" name="MerchantApiResponse[request_status]" value="completed">
        params[:MerchantApiResponse][:request_status] = "completed"
        end

        #             <input type="hidden" name="MerchantApiResponse[status]" value="OK">
        #     <input type="hidden" name="MerchantApiResponse[request_id]" value="11122">
        #     <input type="hidden" name="MerchantApiResponse[request_status]" value="completed">
        #     <input type="hidden" name="MerchantApiResponse[tr_id]" value="22782">
        #     <input type="hidden" name="MerchantApiResponse[sub_account_id]" value="8888">
        #     <input type="hidden" name="MerchantApiResponse[ref_id]" value="1234">
        #     <input type="hidden" name="MerchantApiResponse[msg]" value="">
        #     <input type="hidden" name="MerchantApiResponse[info]" value="">
        #     <input type="hidden" name="MerchantApiResponse[phone_number]" value="demo@paytoo.com">
        #     <input type="hidden" name="MerchantApiResponse[w_number]" value="">

        # Status of transaction. List of possible values:
        # <tt>COMPLETE</tt>::
        def status
          #             <input type="hidden" name="MerchantApiResponse[status]" value="OK">
          params[:MerchantApiResponse][:status]
        end

        def order_ref

          params[:order_ref]

        end

        def request_status
          #     <input type="hidden" name="MerchantApiResponse[request_status]" value="completed">
          params[:MerchantApiResponse][:request_status]
        end

        # Id of this transaction (uniq Paytoo transaction id)
        def transaction_id
          #     <input type="hidden" name="MerchantApiResponse[tr_id]" value="22782">

        params[:MerchantApiResponse][:tr_id]
        end

        def request_id
          #     <input type="hidden" name="MerchantApiResponse[request_id]" value="11122">

        params[:MerchantApiResponse][:request_id]
        end

        # Id of this transaction (uniq Shopify transaction id)
        def reference_id
          #     <input type="hidden" name="MerchantApiResponse[ref_id]" value="1234">

        params[:MerchantApiResponse][:ref_id]
        end

        # The total amount which the payer paid.
        def amount
          #<input type="hidden" name="MerchantApiResponse[PaytooTransaction][tr_amount_total_cost]" value="5.0000">
          params[:MerchantApiResponse][:PaytooTransaction][:tr_amount_total_cost]
        end

        def hash
          #     <input type="hidden" name="MerchantApiResponse[hash]" value="def2e614513fc7cf0d85c97167fb10ab">

        params[:MerchantApiResponse][:hash]
        end

        # The total in fees which was deducted from the amount.
        def fee
          params[:amount_fee]
        end


        def currency
          params[:MerchantApiResponse][:PaytooTransaction][:tr_from_currency]
        end

        # Generated hash depends on params order so use OrderedHash instead of Hash
        def empty!
          super
          @params  = ActiveSupport::OrderedHash.new
        end

        # Acknowledge the transaction to PayFast. This method has to be called after a new
        # ITN arrives. PayFast will verify that all the information we received are correct and will return a
        # VERIFIED or INVALID status.
        #
        # Example:
        #
        #   def pay_fast_itn
        #     notify = PayFastNotification.new(request.raw_post)
        #
        #     if notify.acknowledge
        #       ... process order ... if notify.complete?
        #     else
        #       ... log possible hacking attempt ...
        #     end
        def acknowledge(hash)
          hash == ENV['PAYTOO_HASH']
        end
      end

      class Return < OffsitePayments::Return
      end
    end
  end
end
