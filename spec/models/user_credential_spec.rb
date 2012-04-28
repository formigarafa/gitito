require 'spec_helper'

describe UserCredential do
	def valid_credential
		UserCredential.new(
			:title => "test key", 
			:key => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4d8XdRasriu5HA/GrmNv6wM50TioIgjsW/NcuVnHfuF29SGZkb1mjodDkKVP7BboGIfyE1SG4mgAxv8VGtN3FBtSZPWPCD1zOGwg/uFgbugYgWRLg8IVKoSdDSgG7YwdLF7fktjpUCidFAaYCBnkzDkw+tWt9y79IdgokRwK+bmVuf80xXAr6mD9WLNqTxqXdmCHd9cMePzszdIVUtjIk0R/YHaoCZat+T2D+ICLs2oz2lv+4z5A6who82u6d0X5HDV7dIxf5s8rb/8HGbU1hshsK7VE6SXzph/dj7otkl4Mq4bJ3yLx6l7YktZ9hmVsn+S0zKcnlasD+ND2LM30X user@comment.part.com',
			:user => mock_model(User)
		)
	end

	context "validity" do
		it "validates with valid attributes" do
			valid_credential.should be_valid
		end

		it "fails with no key" do
			credential = valid_credential
			credential.key = ""
			credential.should_not be_valid
		end

	end
end
