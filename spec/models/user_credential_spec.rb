require "spec_helper"

describe UserCredential do
  def valid_credential
    key = [
      "ssh-rsa ",
      "AAAAB3NzaC1yc2EAAAADAQABAAABAQC4d8XdRasriu5HA/GrmNv6wM50TioIgjsW/NcuVnH",
      "fuF29SGZkb1mjodDkKVP7BboGIfyE1SG4mgAxv8VGtN3FBtSZPWPCD1zOGwg/uFgbugYgWR",
      "Lg8IVKoSdDSgG7YwdLF7fktjpUCidFAaYCBnkzDkw+tWt9y79IdgokRwK+bmVuf80xXAr6m",
      "D9WLNqTxqXdmCHd9cMePzszdIVUtjIk0R/YHaoCZat+T2D+ICLs2oz2lv+4z5A6who82u6d",
      "0X5HDV7dIxf5s8rb/8HGbU1hshsK7VE6SXzph/dj7otkl4Mq4bJ3yLx6l7YktZ9hmVsn+S0",
      "zKcnlasD+ND2LM30X user@comment.part.com",
    ].join("")
    UserCredential.new(
      title: "test key",
      key: key,
      user: mock_model(User),
    )
  end

  context "validity" do
    it "validates with valid attributes" do
      credential = valid_credential
      credential.should be_valid
    end

    it "fails with no user" do
      credential = valid_credential
      credential.user = nil
      credential.should_not be_valid
    end

    context "keys" do
      it "fails with no key" do
        credential = valid_credential
        credential.key = ""
        credential.should_not be_valid
      end

      it "fails for duplicated keys" do
        user = mock_model(User)
        key = [
          "ssh-rsa ",
          "AAAAB3NzaC1yc2EAAAADAQABAAABAQC4d8XdRasriu5HA/GrmNv6wM50TioIgjsW/NcuVnH",
          "fuF29SGZkb1mjodDkKVP7BboGIfyE1SG4mgAxv8VGtN3FBtSZPWPCD1zOGwg/uFgbugYgWR",
          "Lg8IVKoSdDSgG7YwdLF7fktjpUCidFAaYCBnkzDkw+tWt9y79IdgokRwK+bmVuf80xXAr6m",
          "D9WLNqTxqXdmCHd9cMePzszdIVUtjIk0R/YHaoCZat+T2D+ICLs2oz2lv+4z5A6who82u6d",
          "0X5HDV7dIxf5s8rb/8HGbU1hshsK7VE6SXzph/dj7otkl4Mq4bJ3yLx6l7YktZ9hmVsn+S0",
          "zKcnlasD+ND2LM30X user@comment.part.com",
        ].join("")
        UserCredential.stub(:generate_authorized_keys_file)
        credential1 = valid_credential
        credential1.key = key
        credential1.user = user
        credential1.save

        credential2 = valid_credential
        credential2.user = user
        credential2.key = key

        credential2.should_not be_valid
      end


      # ref: http://stackoverflow.com/questions/2494450/ssh-rsa-public-key-validation-using-a-regular-expression
      # latter, dont'botter me, yet.
      #it "fails with no spaces separating fields"
      #it "fails when first field not in [ssh-rsa, ssh-dsa]"
      #it "fails when second field can't be base64 decoded"
      #it "fails when decoded second field has wrong leading"
    end
  end

  it "generates authorized_keys line with its key" do
    key = "ssh-rsa AAAAB3NzaC1yc2EA" + "A" * 356
    subject.key = key
    subject.stub(:id).and_return("42")
    expected_line = "command=\"#{Rails.root}/script/ssh-command-proxy.sh 42\" #{key}"

    subject.authorized_keys_line.should == expected_line
  end

  context "authorized_keys generation" do
    subject {UserCredential}

    it { should respond_to :generate_authorized_keys_file }

    it "create folders with 700 mode when specified path doed not exists" do
      Dir.mktmpdir do |tmp_dir|
        auth_keys_file = "#{tmp_dir}/s1/s2/.ssh/authorized_keys"
        auth_keys_folder = File.dirname auth_keys_file

        subject.stub(:authorized_keys_absolute_path).and_return(auth_keys_file)
        File.exists?(auth_keys_folder).should be_falsey
        subject.generate_authorized_keys_file

        File.exists?(auth_keys_folder).should be_truthy
        File.new(auth_keys_folder).stat.mode.to_s(8)[-3..-1].should == "700"
      end
    end

    it "generates empty file with no user credential records" do
      Dir.mktmpdir do |tmp_dir|
        auth_keys_file = "#{tmp_dir}/s1/s2/.ssh/authorized_keys"

        subject.stub(:authorized_keys_absolute_path).and_return(auth_keys_file)
        File.exists?(auth_keys_file).should be_falsey

        subject.generate_authorized_keys_file
        File.new(auth_keys_file).stat.size.should == 0
      end
    end

    it "file generated with 644 mode" do
      previous_umask = File.umask 0
      begin
        Dir.mktmpdir do |tmp_dir|
          auth_keys_file = "#{tmp_dir}/.ssh/authorized_keys"

          subject.stub(:authorized_keys_absolute_path).and_return(auth_keys_file)
          File.exists?(auth_keys_file).should be_falsey

          subject.generate_authorized_keys_file
          File.new(auth_keys_file).stat.mode.to_s(8)[-3..-1].should == "644"
        end
      ensure
        File.umask previous_umask
        File.umask.to_s(8).should == "22"
      end
    end

    it "generates two lines file using two credentials records" do
      Dir.mktmpdir do |tmp_dir|
        auth_keys_file = "#{tmp_dir}/authorized_keys"
        records_mock = []
        records_mock << mock_model(UserCredential, authorized_keys_line: "line1")
        records_mock << mock_model(UserCredential, authorized_keys_line: "line2")

        subject.stub(:all).and_return(records_mock)
        subject.stub(:authorized_keys_absolute_path).and_return(auth_keys_file)

        subject.generate_authorized_keys_file

        generated_file_lines = File.open(auth_keys_file).to_io.read.split("\n")
        generated_file_lines.should include("line1", "line2")
      end
    end
  end
end
