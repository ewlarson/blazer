require_relative "test_helper"

class UploadsTest < ActionDispatch::IntegrationTest
  def setup
    Blazer::Upload.delete_all
    Blazer::UploadsConnection.connection.execute("DROP SCHEMA IF EXISTS uploads CASCADE")
    Blazer::UploadsConnection.connection.execute("CREATE SCHEMA uploads")
  end

  def test_index
    get blazer.uploads_path
    assert_response :success
  end

  def test_new
    get blazer.new_upload_path
    assert_response :success
  end

  def test_create
    create_upload
    assert_response :redirect

    upload = Blazer::Upload.last
    assert_equal "line_items", upload.table
    assert_equal "Billing line items", upload.description

    run_query "SELECT * FROM uploads.line_items"
    assert_response :success

    column_types = Blazer::UploadsConnection.connection.select_all("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'uploads' AND table_name = 'line_items'").rows.to_h
    assert_equal "bigint", column_types["a"]
    assert_equal "numeric", column_types["b"]
    assert_equal "timestamp with time zone", column_types["c"]
    assert_equal "date", column_types["d"]
    assert_equal "text", column_types["e"]
    assert_equal "text", column_types["f"]
  end

  def test_create_duplicate_table
    create_upload
    assert_response :redirect
    create_upload
    assert_response :unprocessable_entity
  end

  def test_rename
    create_upload
    assert_response :redirect

    upload = Blazer::Upload.last
    patch blazer.upload_path(upload), params: {upload: {table: "items"}}
    assert_response :redirect

    tables = Blazer::UploadsConnection.connection.select_all("SELECT table_name FROM information_schema.tables WHERE table_schema = 'uploads'").rows.map(&:first)
    assert_equal ["items"], tables
  end

  def create_upload
    post blazer.uploads_path, params: {upload: {table: "line_items", description: "Billing line items", file: fixture_file_upload("test/support/line_items.csv", "text/csv")}}
  end
end