require 'test_helper'

# Clase para probar el modelo "ImageModel"
class ImageModelTest < ActiveSupport::TestCase
  fixtures :image_models

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @image_model = ImageModel.find image_models(:image_one).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of ImageModel, @image_model
    assert_equal image_models(:image_one).image_file_name,
      @image_model.image_file_name
    assert_equal image_models(:image_one).image_content_type,
      @image_model.image_content_type
    assert_equal image_models(:image_one).image_file_size,
      @image_model.image_file_size
  end

  # Prueba la creación de un modelo de archivo
  test 'create' do
    assert_difference 'ImageModel.count' do
      @image_model = ImageModel.create(
        :image_file_name => 'new_file.jpg',
        :image_content_type => 'image/gif',
        :image_file_size => 2000
      )
    end
  end

  # Prueba de actualización de un modelo de archivo
  test 'update' do
    assert @image_model.update_attributes(:image_file_name => 'updated_name'),
      @image_model.errors.full_messages.join('; ')
    @image_model.reload
    assert_equal 'updated_name', @image_model.image_file_name
  end

  # Prueba de eliminación de un modelo de archivo
  test 'delete' do
    assert_difference('ImageModel.count', -1) do
      # Elimina la dependencia para evitar problemas con la clave foránea
      Organization.update_all(
        {:image_model_id => nil},
        {:image_model_id => @image_model.id}
      )

      @image_model.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates lenght attributes' do
    @image_model.image_file_name = 'abc' * 100
    @image_model.image_content_type = "image/#{'abc' * 100}"
    assert @image_model.invalid?
    assert_equal 2, @image_model.errors.count
    assert_equal [error_message_from_model(@image_model, :image_file_name,
        :too_long, :count => 255)], @image_model.errors[:image_file_name]
    assert_equal [error_message_from_model(@image_model, :image_content_type,
      :too_long, :count => 255)], @image_model.errors[:image_content_type]
  end
end
