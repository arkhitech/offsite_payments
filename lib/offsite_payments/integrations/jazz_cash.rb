module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module JazzCash
      #JazzCash Integration for HTTP Redirect v1.1
      
      mattr_accessor :test_url
      self.test_url = 'https://sandbox.jazzcash.com.pk/CustomerPortal/transactionmanagement/merchantform/'
      mattr_accessor :production_url
      self.production_url = 'https://jazzcash.com.pk/CustomerPortal/transactionmanagement/merchantform/'

      def self.service_url
        mode = OffsitePayments.mode
        case mode
        when :production
          self.production_url
        when :test
          self.test_url
        else
          raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      def self.notification(post, options = {})
        Notification.new(post)
      end

      def self.return(query_string, options = {})
        Return.new(query_string)
      end

      class Helper < OffsitePayments::Helper
        def initialize(order, account, options = {})
          super
          add_field('pp_Version', options[:pp_Version])
          add_field('pp_TxnType', options[:pp_TxnType])
          add_field('pp_Language', 'EN')
          add_field('pp_MerchantID', options[:pp_MerchantID])
          add_field('pp_SubMerchantID', options[:pp_SubMerchantID])
          add_field('pp_Password', options[:pp_Password])
          add_field('pp_BankID', options[:pp_BankID])
          add_field('pp_ProductID', options[:pp_ProductID])
          add_field('pp_TxnRefNo', options[:pp_TxnRefNo])
          add_field('pp_Amount', options[:pp_Amount])
          add_field('pp_TxnCurrency', options[:pp_TxnCurrency])
          add_field('pp_TxnDateTime', options[:pp_TxnDateTime])
          add_field('pp_Description', options[:pp_Description])
          add_field('pp_TxnExpiryDateTime', options[:pp_TxnExpiryDateTime])
          add_field('pp_ReturnURL', options[:pp_ReturnURL])
          add_field('pp_SecureHash', options[:pp_SecureHash])
          add_field('ppmpf_1', '1')
          add_field('ppmpf_2', '2')
          add_field('ppmpf_3', '3')
          add_field('ppmpf_4', '4')
          add_field('ppmpf_5', '5')
        end

        mapping :order, 'pp_TxnRefNo'
        mapping :amount, 'pp_Amount'
        mapping :account, 'account'
        mapping :currency, 'pp_TxnCurrency'
        mapping :notify_url, 'notify_url'
        mapping :return_url, 'pp_ReturnURL'
        mapping :cancel_return_url, 'cancel_return'
      end
      
      class Notification < OffsitePayments::Notification
        include ActiveUtils::PostsData

        def initialize(post, options = {})
          super
        end
        
        def complete?
          status == "Completed"
        end
        
        def status
          params['payment_status']
        end

        def account
          params['pp_Amount']
        end

        # Acknowledge the transaction to paypal. This method has to be called after a new
        # ipn arrives. Paypal will verify that all the information we received are correct and will return a
        # ok or a fail.
        #
        # Example:
        #
        #   def paypal_ipn
        #     notify = PaypalNotification.new(request.raw_post)
        #
        #     if notify.acknowledge
        #       ... process order ... if notify.complete?
        #     else
        #       ... log possible hacking attempt ...
        #     end
        
        def acknowledge(authcode = nil)
          # payload =  raw
          #
          # response = ssl_post(Paypal.service_url + '?cmd=_notify-validate', payload,
          #   'Content-Length' => "#{payload.size}",
          #   'User-Agent'     => "Active Merchant -- http://activemerchant.org"
          # )
          #
          # raise StandardError.new("Faulty paypal result: #{response}") unless ["VERIFIED", "INVALID"].include?(response)
          #
          # response == "VERIFIED"
        end
      end

      class Return < OffsitePayments::Return
      end
    end
  end
end
