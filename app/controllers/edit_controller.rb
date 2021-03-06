require "./app/models/fast_service.rb"

class EditController < ApplicationController
  # =====================================================
  # In Rails 5.x skip_before_filter has been removed,
  # it should be replaced with skip_before_action but
  # then we run into the problem that authenticate_user!
  # has not been defined.
  #
  # Since this controller is currently not being used we
  # comment the line altogether.
  #
  # # TODO enable session protection once
  # skip_before_filter :authenticate_user!
  # =====================================================
  def edit
    must_be_authenticated()

    @new_editor = new_editor_request()
    # TODO: be more gentle on the error display
    raise "Edit not allowed" if !@new_editor

    id = params["id"]
    type = ModelUtils.type_for_id(id)
    if type != "PEOPLE"
      raise "Cannot edit record type #{type}."
    end

    faculty = Faculty.load_from_solr(id)
    if faculty == nil
      Rails.logger.error("Could not load faculty #{id} for edit.")
      render "error", status: 500
      return
    end

    force_show_viz = params[:viz] == "true"
    faculty.load_edit_data()
    referer = search_url()

    @presenter = FacultyPresenter.new(faculty.item, search_url(), referer, force_show_viz)
    @presenter.user = current_user
    @presenter.edit_mode = true
    @presenter.edit_errors = faculty.errors
    @presenter.edit_allowed = faculty.errors.count == 0 && current_user.can_edit?(id)
    @vivo_id = id
    render "faculty/show"

  rescue => ex
    backtrace = ex.backtrace.join("\r\n")
    Rails.logger.error("Could not edit record #{id}. Exception: #{ex} \r\n #{backtrace}")
    render "error", status: 500
  end

  def fast_search
    results = []
    text = (params[:text] || "").strip
    if (text.length >= 3)
      results = FastService.search(text, true)
    end
    render :json => {status: 200, data: results}
  end

  def overview_update
    must_be_authenticated("json")
    if !new_editor_request()
      render_not_authorized()
      return
    end

    faculty_id = params[:faculty_id]
    text = params[:text]
    text, error = FacultyEdit.simple_text_update("overview/overview/update", faculty_id, text, "overview")
    render_output({text: text}, error)
  end

  def research_area_add
    must_be_authenticated("json")
    if !new_editor_request()
      render_not_authorized()
      return
    end
    faculty_id = params[:faculty_id]
    text = params[:text]
    rab_id, error = FacultyEdit.research_area_add(faculty_id, text)
    render_output({id: ModelUtils::vivo_id(rab_id)}, error)
  end

  def research_area_delete
    must_be_authenticated("json")
    if !new_editor_request()
      render_not_authorized()
      return
    end
    faculty_id = params[:faculty_id]
    id = params[:id]
    _, error = FacultyEdit.research_area_delete(faculty_id, id)
    render_output(nil, error)
  end

  def web_link_save
    must_be_authenticated("json")
    return if !new_editor_request()
    faculty_id = params[:faculty_id]
    text = params[:text]
    url = params[:url]
    rank = params[:rank]
    id = params[:id]
    rab_id, error = FacultyEdit.web_link_save(faculty_id, text, url, rank, id)
    data = {
      id: ModelUtils::vivo_id(rab_id),
      text: text,
      url: url,
      rank: rank
    }
    render_output(data, error)
  end

  def web_link_delete
    must_be_authenticated("json")
    return if !new_editor_request()
    faculty_id = params[:faculty_id]
    id = params[:id]
    _, error = FacultyEdit.web_link_delete(faculty_id, id)
    render_output(nil, error)
  end

  def research_overview_update
    must_be_authenticated("json")
    return if !new_editor_request()
    faculty_id = params[:faculty_id]
    text = params[:text]
    text, error = FacultyEdit.simple_text_update("research/overview/update", faculty_id, text, "research_overview")
    render_output({text: text}, error)
  end

  def research_statement_update
    must_be_authenticated("json")
    if !new_editor_request()
      render_not_authorized()
      return
    end
    faculty_id = params[:faculty_id]
    text = params[:text]
    text, error = FacultyEdit.simple_text_update("research/statement/update", faculty_id, text, "research_statement")
    render_output({text: text}, error)
  end

  def research_funded_update
    must_be_authenticated("json")
    if !new_editor_request()
      render_not_authorized()
      return
    end
    faculty_id = params[:faculty_id]
    text = params[:text]
    text, error = FacultyEdit.simple_text_update("research/funded/update", faculty_id, text, "funded_research")
    render_output({text: text}, error)
  end

  def research_scholarly_update
    must_be_authenticated("json")
    if !new_editor_request()
      render_not_authorized()
      return
    end
    faculty_id = params[:faculty_id]
    text = params[:text]
    text, error = FacultyEdit.simple_text_update("research/scholarly/update", faculty_id, text, "scholarly_work")
    render_output({text: text}, error)
  end

  def background_awards_update
    must_be_authenticated("json")
    if !new_editor_request()
      render_not_authorized()
      return
    end
    faculty_id = params[:faculty_id]
    text = params[:text]
    text, error = FacultyEdit.simple_text_update("background/honors/update", faculty_id, text, "awards_honors")
    render_output({text: text}, error)
  end

  def affiliations_text_update
    must_be_authenticated("json")
    if !new_editor_request()
      render_not_authorized()
      return
    end
    faculty_id = params[:faculty_id]
    text = params[:text]
    text, error = FacultyEdit.simple_text_update("affiliations/affiliations/update", faculty_id, text, "affiliations")
    render_output({text: text}, error)
  end

  def teaching_overview_update
    must_be_authenticated("json")
    if !new_editor_request()
      render_not_authorized()
      return
    end
    faculty_id = params[:faculty_id]
    text = params[:text]
    text, error = FacultyEdit.simple_text_update("teaching/overview/update", faculty_id, text, "teaching_overview")
    render_output({text: text}, error)
  end

  private
    def render_not_authorized()
      render :json => {}, status: 401
    end

    def render_output(data, error)
      if error != nil
        Rails.logger.error(error)
        render :json => {error: error}, status: 400
      else
        render :json => data || {}, status: 200
      end
    end
end
