require 'test/unit'
require 'lib/address_book_importer'

class TestAddressBookImporter < Test::Unit::TestCase

  GMAIL_TEST = {:username => '', :password => ''}
  HOTMAIL_TEST = {:username => '', :password => ''}
  YAHOO_TEST = {:username => '', :password => ''}
  
  def setup
    raise 'fixme: open accounts for testing purposes'
  end

  def test_gmail
    a = AddressBookImporter::Gmail.new(GMAIL_TEST[:username],GMAIL_TEST[:password])
    puts 'GMAIL = ' + a.contacts.inspect
    assert !a.contacts.empty?
  end

  def test_hotmail
    a = AddressBookImporter::Hotmail.new(HOTMAIL_TEST[:username], HOTMAIL_TEST[:password])
    puts 'HOTMAIL = ' + a.contacts.inspect
    assert !a.contacts.empty?
  end

  def test_yahoo
    a = AddressBookImporter::Yahoo.new(YAHOO_TEST[:username], YAHOO_TEST[:password])
    puts 'YAHOO = ' + a.contacts.inspect
    assert !a.contacts.empty?
  end
end
