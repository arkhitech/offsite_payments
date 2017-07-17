# require 'offsite_payments/integrations/easy_paisa/helper'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module EasyPaisa

      module_function
    
      class Helper < OffsitePayments::Helper


        def credential_based_url
          if self.fields['authcode']
            "https://easypaystg.easypaisa.com.pk/easypay/Confirm.jsf"
          else
            "https://easypaystg.easypaisa.com.pk/easypay/Index.jsf"
          end
        end
        
        attr_accessor :errors

        def initialize(order, account, options = {})   
          super   
          if options[:authcode]
            
            add_field('auth_token', options[:authcode])
            add_field('postBackURL', options[:return_url])
            
          else
            expiry_date=(Time.now.tomorrow).strftime("%Y%m%d %H%M%S")
            request_params = {
              'storeId' => options[:account_name],
              'amount' => options[:amount].to_s,
              'postBackURL' => options[:return_url],
              'orderRefNum'=> "#{order}",
              'expiryDate' => "#{expiry_date}",
              'autoRedirect' => '0',
              'paymentMethod' => 'CC_PAYMENT_METHOD', 
              'emailAddr' => options[:credential2], 
              'mobileNum' => options[:credential3]     
            }

            add_field('storeId', options[:account_name])
            add_field('amount', options[:amount])
            add_field('postBackURL', options[:return_url])
            add_field('orderRefNum', "#{order}")
            add_field('expiryDate', "#{expiry_date}")
            add_field('autoRedirect', 0)
            add_field('paymentMethod', 'CC_PAYMENT_METHOD')
            add_field('emailAddr', options[:credential2])
            add_field('mobileNum', options[:credential3])
            add_field('merchantHashedReq', signed_request(options[:credential4], request_params))
          end
         
        end 
        
                
        def errors
          @error ||= []
        end
        
        require 'openssl'
        require 'base64'
        
        def encrypt(raw_data, key)
          cipher = OpenSSL::Cipher.new("AES-128-ECB")
          cipher.encrypt()
          
          #convert key to hex key and pack (requirement for java padding
          hex_key = key.bytes.map { |b| sprintf("%02X",b) }.join  
          key = [hex_key].pack('H*')
          
          cipher.key = key
          crypt = cipher.update(raw_data) + cipher.final

          Base64.encode64(crypt)
        end

        def signed_request(hashKey, request_params)
          sorted_keys = request_params.keys.sort
          sorted_pairs = []
          sorted_keys.each do |key|
            sorted_pairs << "key=#{request_params[key]}"
          end
          
          encrypt(sorted_pairs.join('&'), hashKey)
        end
        

        # Replace with the real mapping

        
#        mapping :store_id, 'store_id'
#        mapping :amount, 'amount'
#        mapping :post_back_url, 'postBackURL'
#        mapping :order, 'orderRefNum'
#        mapping :expiry_date, 'expiryDate'
#        mapping :merchant_hashed_req, 'merchantHashedReq'
#        mapping :auto_redirect, 'autoRedirect'
#        mapping :payment_method, 'paymentMethod'
#        mapping :email_address, 'emailAddr'
#        mapping :phone_number, 'mobileNum'
        
        
        
#        mapping :auth_token, 'AuthToken'


        # mapping :customer, :first_name => '',
        #                    :last_name  => '',
        #                    :email      => '',
        #                    :phone      => ''
        #
        # mapping :billing_address, :city     => '',
        #                           :address1 => '',
        #                           :address2 => '',
        #                           :state    => '',
        #                           :zip      => '',
        #                           :country  => ''
        #
        # mapping :tax, ''
        # mapping :shipping, ''
      end
      
      
      class Notification < OffsitePayments::Notification
        
        def errors
          @error ||= []
        end
        
        def identifier
          params[:identifier]
        end
        
        def amount
          params[:amount].to_f
        end
        
        
        def transaction_number
          params[:transactionNumber]
        end
        
        def authorization
          transaction_number
        end
        
        def avs_result
          {}
        end
        
        def cvv_result
          nil
        end
        
        def acknowledge(authcode = nil)
          unless params[:success]=="true" && params[:transactionResponse]=="Transaction Successful."
            errors << "Transaction Unsuccessful. For more information, please contact your card issuing bank."
            false
          else
            true
          end
        end
        
        def success?
          errors.empty?
        end
        
        
                # Take the posted data and move the relevant data into a hash
        def parse(post)
          case post
          when Hash
            post.each_pair do |k, v|
              params[k.to_sym] = v
            end
          else
            @raw = post.to_s
            for line in @raw.split('&')
              key, value = *line.scan( %r{^([A-Za-z0-9_.-]+)\=(.*)$} ).flatten
              params[key] = CGI.unescape(value.to_s) if key.present?
            end            
          end
        end
          
      end
      
      
      
    end
  end
end
