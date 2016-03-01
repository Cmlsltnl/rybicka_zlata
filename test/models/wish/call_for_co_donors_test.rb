require 'test_helper'

class WishBookingTest < ActiveSupport::TestCase
     
  def setup
    setup_wish
  end  

  def test_when_available_no_called_id
    @wish.state=Wish::State::STATE_AVAILABLE
    @wish.called_for_co_donors_by_id=nil
    assert @wish.valid?

    @wish.called_for_co_donors_by_id=@donor.id
    refute @wish.valid?
    assert @wish.errors[:called_for_co_donors_by_id].present?
  end  

  def test_cannot_be_called_by_author
    @wish.state=Wish::State::STATE_CALL_FOR_CO_DONORS
    @wish.called_for_co_donors_by_id=@author.id
    refute @wish.valid?
    assert @wish.errors[:called_for_co_donors_by_id].present?
  end  

  def test_cannot_be_called_by_donee
    @wish.state=Wish::State::STATE_CALL_FOR_CO_DONORS
    @wish.called_for_co_donors_by_id=@donee.id
    refute @wish.valid?
    assert @wish.errors[:called_for_co_donors_by_id].present?
  end  
  
  def test_cannot_be_in_call_for_co_donors_without_called_for_co_donors_by_id
    @wish.state=Wish::State::STATE_CALL_FOR_CO_DONORS

    @wish.called_for_co_donors_by_id=nil
    refute @wish.valid?
    assert @wish.errors[:called_for_co_donors_by_id].present?

    @wish.called_for_co_donors_by_id=@donor.id
    assert @wish.valid?, "errors: #{@wish.errors.full_messages}"
  end 

  def test_cannot_be_gifted_without_called_for_co_donors_by_id
    for state in [Wish::State::STATE_GIFTED, Wish::State::STATE_RESERVED]
    @wish.called_for_co_donors_by_id=nil
    assert @wish.valid?
  end 

  def test_can_be_fullfiled_without_called_for_co_donors_by_id
    @wish.state=Wish::State::STATE_FULFILLED

    @wish.called_for_co_donors_by_id=nil  #can be fullfiled by person out of this app
    assert @wish.valid?  
    
    @wish.called_for_co_donors_by_id=@donor.id #or from this app
    assert @wish.valid?
  end 
end  
