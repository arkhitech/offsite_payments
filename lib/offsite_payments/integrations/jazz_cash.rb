module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module JazzCash
      #JazzCash Integration for HTTP Redirect v1.1

      def self.notification(post, options = {})
        Notification.new(post)
      end

      def self.return(query_string, options = {})
        Return.new(query_string)
      end

      class Helper < OffsitePayments::Helper
        attr_accessor :salt
        attr_accessor :valid_till

        def credential_based_url
          unless test?
            'https://payments.jazzcash.com.pk/CustomerPortal/transactionmanagement/merchantform'
          else
            "https://sandbox.jazzcash.com.pk/CustomerPortal/transactionmanagement/merchantform"
          end
        end

        def initialize(order, account, options = {})
          super
        end

        mapping :order, 'pp_TxnRefNo'
        mapping :account, 'pp_MerchantID'
        mapping :amount, 'pp_Amount'
        mapping :currency, 'pp_TxnCurrency'
        mapping :credential2, 'pp_Password'
        mapping :return_url, 'pp_ReturnURL'

        def transaction_time
          @transaction_time ||= Time.now
        end
            
        def transaction_time_str
          transaction_time.strftime("%Y%m%d%H%M%S")
        end
      
        def transaction_expiry_time_str
          valid_till.strftime("%Y%m%d%H%M%S")
        end
      
        def secure_hash          
          hash_items = []
          hash_items << self.salt 
          hash_items << self.fields['pp_Amount']
          hash_items << self.fields['pp_BankID']
          hash_items << self.fields['pp_BillReference']
          hash_items << self.fields['pp_Description']
          hash_items << self.fields['pp_Language']
          hash_items << self.fields['pp_MerchantID']
          hash_items << self.fields['pp_Password']
          hash_items << self.fields['pp_ProductID']
          hash_items << self.fields['pp_ReturnURL']
          hash_items << self.fields['pp_TxnCurrency']
          hash_items << self.fields['pp_TxnDateTime']
          hash_items << self.fields['pp_TxnExpiryDateTime']
          hash_items << self.fields['pp_TxnDateTime']
          hash_items << self.fields['pp_Version']
          hash_items << '1'
          hash_items << '2'
          hash_items << '3'
          hash_items << '4'
          hash_items << '5'
          hash_items.join('&')

          OpenSSL::HMAC.hexdigest('SHA256', self.salt, hash_items.join('&'))
        end

        def form_fields
          raise 'salt is not set' unless salt
          raise 'valid_till is not set' unless valid_till

          self.add_field('pp_TxnDateTime', transaction_time_str)
          self.add_field('pp_TxnExpiryDateTime', transaction_expiry_time_str)      
          self.add_field('ppmpf_1', '1')
          self.add_field('ppmpf_2', '2')
          self.add_field('ppmpf_3', '3')
          self.add_field('ppmpf_4', '4')
          self.add_field('ppmpf_5', '5')
        
          self.add_field('pp_SecureHash', secure_hash)

          self.fields.assert_valid_keys(%w(pp_ReturnURL pp_Version pp_Language pp_BankID pp_ProductID 
            pp_IsRegisteredCustomer pp_CustomerID pp_CustomerEmail 
            pp_CustomerMobile pp_TxnType pp_TxnRefNo pp_MerchantID pp_SubMerchantID pp_Password pp_Amount pp_TxnCurrency 
            pp_TxnDateTime pp_TxnExpiryDateTime pp_BillReference pp_Description pp_CustomerCardNumber 
            pp_CustomerCardExpiry pp_CustomerCardCvv pp_SecureHash pp_DiscountedAmount pp_DiscountBank
            ppmpf_1 ppmpf_2 ppmpf_3 ppmpf_4 ppmpf_5
            ))
          super
        end
      end
      
      class Notification < OffsitePayments::Notification
        include ActiveUtils::PostsData

        # "summaryStatus":"CARD_NOT_ENROLLED",
        # "pp_CustomerID":"test",
        # "pp_CustomerEmail":"test@test.com",
        # "pp_CustomerMobile":"033456789025",
        # "result_CardEnrolled":"CARD_NOT_ENROLLED",
        # "c3DSecureID":"20190515095244486750",
        # "aR_Simple_Html":"",
        # "secureHash":"",
        # "pp_IsRegisteredCustomer":"Yes",
        # "responseCode":"433",
        # "responseMessage":"Card holder is not enrolled"        
        def initialize(post, options = {})
          super
          @raw = post
          @params = post
        end

        def errors
          @error ||= []
        end

        def summary_status
          @params['summaryStatus']
        end
        
        def customer_id
          @params['pp_CustomerID']
        end
        
        def customer_email
          @params['pp_CustomerEmail']
        end
        
        def customer_mobile
          @params['pp_CustomerMobile']
        end

        def result_card_enrolled
          @params['result_CardEnrolled']
        end

        def c3d_secure_id
          @params['c3DSecureID']
        end
        
        def ar_simple_html
          @params['aR_Simple_Html']
        end

        def secure_hash
          @params['secureHash']
        end

        def is_registered_customer
          @params['pp_IsRegisteredCustomer']
        end

        def response_code
          @params['pp_ResponseCode']
        end

        def response_message
          @params['pp_ResponseMessage']
        end

        def status
          response_code
        end
        
        def success?
          @params['pp_ResponseCode'] == '000'
        end
        
        def status_message
          response_message
        end

        def acknowledge(authcode = nil)
          if @params['pp_ResponseCode'] == '000'
            true
          else
            errors << "#{@params['pp_ResponseMessage']}"
            false
          end
        end
      end

      class Return < OffsitePayments::Return
      end
    end
  end
end
