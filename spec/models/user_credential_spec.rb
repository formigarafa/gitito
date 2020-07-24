# frozen_string_literal: true

require "spec_helper"

describe UserCredential do
  def valid_credential
    charset = ("a".."z").to_a
    charset += charset.map(&:upcase) + (0..9).to_a.map(&:to_s) + ["+", "/"]
    key = Array.new(372) { charset.sample }
    key = "ssh-rsa #{key} user@comment.part.com"
    UserCredential.new(
      title: "test key",
      key: key,
      user: mock_model(User),
    )
  end

  context "validity" do
    it "validates with valid attributes" do
      credential = valid_credential
      expect(credential).to be_valid
    end

    it "fails with no user" do
      credential = valid_credential
      credential.user = nil
      expect(credential).to_not be_valid
    end

    context "keys" do
      it "fails with no key" do
        credential = valid_credential
        credential.key = ""
        expect(credential).to_not be_valid
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
        allow(described_class).to receive(:generate_authorized_keys_file)
        credential1 = valid_credential
        credential1.key = key
        credential1.user = user
        credential1.save

        credential2 = valid_credential
        credential2.user = user
        credential2.key = key

        expect(credential2).to_not be_valid
      end

      # ref: http://stackoverflow.com/questions/2494450/ssh-rsa-public-key-validation-using-a-regular-expression
      # latter, dont'botter me, yet.
      # it "fails with no spaces separating fields"
      # it "fails when first field not in [ssh-rsa, ssh-dsa]"
      # it "fails when second field can't be base64 decoded"
      # it "fails when decoded second field has wrong leading"
    end
  end

  it "generates authorized_keys line with its key" do
    key = "ssh-rsa AAAAB3NzaC1yc2EA" + "A" * 356
    subject.key = key
    allow(subject).to receive(:id).and_return("42")
    expected_line = "command=\"#{Rails.root}/script/ssh-command-proxy.sh 42\" #{key}"

    expect(subject.authorized_keys_line).to eq expected_line
  end

  context "authorized_keys generation" do
    subject { described_class }

    it { is_expected.to respond_to :generate_authorized_keys_file }

    it "create folders with 700 mode when specified path doed not exists" do
      Dir.mktmpdir do |tmp_dir|
        auth_keys_file = "#{tmp_dir}/s1/s2/.ssh/authorized_keys"
        auth_keys_folder = File.dirname auth_keys_file

        allow(subject).to receive(:authorized_keys_absolute_path).and_return(auth_keys_file)
        expect(File.exist?(auth_keys_folder)).to be_falsey
        subject.generate_authorized_keys_file

        expect(File.exist?(auth_keys_folder)).to be_truthy
        expect(File.new(auth_keys_folder).stat.mode.to_s(8)[-3..-1]).to eq "700"
      end
    end

    it "generates empty file with no user credential records" do
      Dir.mktmpdir do |tmp_dir|
        auth_keys_file = "#{tmp_dir}/s1/s2/.ssh/authorized_keys"

        allow(subject).to receive(:authorized_keys_absolute_path).and_return(auth_keys_file)
        expect(File.exist?(auth_keys_file)).to be_falsey

        subject.generate_authorized_keys_file
        expect(File.new(auth_keys_file).stat.size).to eq 0
      end
    end

    it "file generated with 644 mode" do
      previous_umask = File.umask 0
      begin
        Dir.mktmpdir do |tmp_dir|
          auth_keys_file = "#{tmp_dir}/.ssh/authorized_keys"

          allow(subject).to receive(:authorized_keys_absolute_path).and_return(auth_keys_file)
          expect(File.exist?(auth_keys_file)).to be_falsey

          subject.generate_authorized_keys_file
          expect(File.new(auth_keys_file).stat.mode.to_s(8)[-3..-1]).to eq "644"
        end
      ensure
        File.umask previous_umask
        expect(File.umask.to_s(8)).to eq "22"
      end
    end

    xit "generates two lines file using two credentials records" do
      Dir.mktmpdir do |tmp_dir|
        auth_keys_file = "#{tmp_dir}/authorized_keys"
        records_mock = []
        records_mock << mock_model(described_class, authorized_keys_line: "line1")
        records_mock << mock_model(described_class, authorized_keys_line: "line2")

        allow(subject).to receive(:all).and_return(records_mock)
        allow(subject).to receive(:authorized_keys_absolute_path).and_return(auth_keys_file)

        subject.generate_authorized_keys_file

        generated_file_lines = File.open(auth_keys_file).to_io.read.split("\n")
        expect(generated_file_lines).to include("line1", "line2")
      end
    end
  end
end
