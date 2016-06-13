class JobsController < ApplicationController
  # GET /jobs
  # GET /jobs.json
  def index
    begin
      @dic = Dictionary.accessible(current_user).find_by_name(params[:dictionary_id])
      raise "There is no such dictionary." unless @dic.present?
      @jobs = @dic.jobs.order(:created_at)

      respond_to do |format|
        format.html { redirect_to dictionary_path(@dic.name) if @jobs.length == 0}
        format.json { render json: @jobs }
      end
    rescue
      respond_to do |format|
        format.html { redirect_to dictionary_path(@dic.name) }
        format.json { render status: :no_content }
      end
    end
  end

  # GET /jobs/1
  # GET /jobs/1.json
  def show
    @job = Job.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @job }
    end
  end

  # GET /jobs/new
  # GET /jobs/new.json
  def new
    @job = Job.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @job }
    end
  end

  # GET /jobs/1/edit
  def edit
    @job = Job.find(params[:id])
  end

  # POST /jobs
  # POST /jobs.json
  def create
    @job = Job.new(params[:job])

    respond_to do |format|
      if @job.save
        format.html { redirect_to @job, notice: 'Job was successfully created.' }
        format.json { render json: @job, status: :created, location: @job }
      else
        format.html { render action: "new" }
        format.json { render json: @job.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /jobs/1
  # PUT /jobs/1.json
  def update
    @job = Job.find(params[:id])

    respond_to do |format|
      if @job.update_attributes(params[:job])
        format.html { redirect_to @job, notice: 'Job was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @job.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /jobs/1
  # DELETE /jobs/1.json
  def destroy
    job = Job.find(params[:id])
    job.destroy_if_not_running

    respond_to do |format|
      format.html { redirect_to :back }
      format.json { head :no_content }
    end
  end
end
