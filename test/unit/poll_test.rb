require 'test_helper'

class PollTest < ActiveSupport::TestCase
 def setup
    @poll = Poll.find polls(:poll_one).id
  end
  
  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Poll, @poll
    assert_equal polls(:poll_one).comments, @poll.comments
    assert_equal polls(:poll_one).questionnaire.id, @poll.questionnaire.id
    assert_equal polls(:poll_one).user.id, @poll.user.id
  end
  
  # Prueba la creación de una encuesta
  test 'create' do
    assert_difference ['Poll.count', 'Answer.count'] do
      Poll.create(
        :comments => 'New comments',
        :questionnaire_id => questionnaires(:questionnaire_one).id,
        :answers_attributes => {
          '1' => {
            :answer => 'Answer'
          }
        }
       )
    end
  end
  
  # Prueba de actualización de una encuesta
  test 'update' do
    assert @poll.update_attributes(:comments => 'Updated comments'),
      @poll.errors.full_messages.join('; ')
    @poll.reload
    assert_equal 'Updated comments', @poll.comments
  end
  
  # Prueba de eliminación de una encuesta
  test 'delete' do
    assert_difference 'Poll.count', -1 do
      assert_difference 'Answer.count', -2 do
        @poll.destroy     
      end
    end
  end
  
  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @poll.comments = 'abcde' * 52
    assert @poll.invalid?
    assert_equal 1, @poll.errors.count
    assert_equal [error_message_from_model(@poll, :comments, :too_long,
      :count => 255)], @poll.errors[:comments]
  end
  
end
