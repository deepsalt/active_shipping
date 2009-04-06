module ActiveMerchant
  module Shipping
    class Endicia < Carrier
      TEST_SERVER = 'https://www.envmgr.com/LabelService/EwsLabelService.asmx'

      private

      def requirements
        [:account_id, :passphrase]
      end

      def build_label_request(shipment, package)
        xml = Builder::XmlMarkup.new
        xml.instruct!
        xml.LabelRequest('Test' => 'YES') do
          xml.RequesterID
          xml.AccountID @options[:account_id]
          xml.PassPhrase @options[:passphrase]
          xml.MailClass shipment.service
          xml.WeightOz package.ounces
          xml.MailpieceShape 'Parcel'
          xml.Services 'InsuredMail' => 'OFF', 'SignatureConfirmation' => 'OFF'
          xml.PartnerCustomerID
          xml.PartnerTransactionID
          add_location_element(xml, 'To', shipment.destination)
          add_location_element(xml, 'From', shipment.origin)
          xml.ResponseOptions 'PostagePrice' => 'TRUE'
        end
        xml.target!
      end

      def add_location_element(xml, name, object)
        if object.attention.blank?
          xml.tag!(name + 'Name', object.name)
        else
          xml.tag!(name + 'Name', object.attention)
          xml.tag!(name + 'Company', object.name)
        end
        values = [
          [object.address1, 'Address1'],
          [object.address2, 'Address2'],
          [object.address3, 'Address3'],
          [object.city, 'City'],
          [object.state, 'State'],
          [object.postal_code, 'PostalCode'],
          [object.phone, 'Phone']
        ]
        values.select {|v, n| !v.blank?}.each do |v, n|
          xml.tag!(name + n, v)
        end
      end

      def get_postage_label
      end

      def buy_postage
      end

      def change_pass_phrase
      end

      def calculate_postage_rate
      end

      def get_account_status
      end

      def refund_request
      end

      def user_signup
      end

      def status_request
      end

      def get_transactions_listing
      end

      def scan_request
      end

      def carrier_pickup_request
      end

      def carrier_pickup_cancel
      end

      def carrier_pickup_change
      end

      def multi_location_carrier_pickup
      end
    end
  end
end
