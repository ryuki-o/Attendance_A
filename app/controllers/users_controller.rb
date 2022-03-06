class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :correct_user, only: [:edit, :update, :show]
  before_action :admin_user, only: [:destroy, :update, :edit_basic_info, :update_basic_info]
  before_action :set_one_month, only: :show

  def index
    @users = User.all
    # respond_to do |format|
    #   format.html do
    #     #html用の処理を書く
    # end 
    #   format.csv do
    #     #csv用の処理を書く
    #     send_data render_to_string, filename: "(ファイル名).csv", type: :csv
    # end
  end
    
    # if params[:name].present?
    #   @users = User.get_by_name params[:name]
    # end
    # if params[:id].present?
    #   @user = User.find_by(id: @users.id)
    # else
    #   @user = User.new
    # end
  # end
  
  def index_attendance
    @users = User.all.includes(:attendances)
  end
      
  
  def import
    if params[:csv_file].blank?
      redirect_to action: 'index', error: '読み込むCSVを選択してください'
    elsif File.extname(params[:csv_file].original_filename) != ".csv"
      redirect_to action: 'index', notice: 'csvファイルのみ読み込み可能です'
    # elsif User.exists?(name: "濱本 亮")
      # redirect_to action: 'index', notice: 'そのユーザーはすでに存在しています'
    else
       results = User.import(params[:csv_file])
       redirect_to action: 'index', notice: "#{ results.to_s }件のエラーが発生しました"
        p  results.failed_instances  # 戻り値で、失敗したインスタンスを配列で取得する
      # num = User.import(params[:csv_file])
      # redirect_to action: 'index', notice: "#{ num.to_s }件のデータ情報を追加/更新しました"
    end
  end
  
  def show
    @user = User.find(params[:id])
    @worked_sum = @attendances.where.not(started_at: nil).count
    @attendance = Attendance.where(confirmation: '申請中')
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = '新規作成に成功しました。'
      redirect_to @user
    else
      render :new
    end
  end

  def edit
  end

  def update
    @users = User.paginate(page: params[:page], per_page: 20)
    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      flash[:success] = "ユーザー情報を更新しました。"
      redirect_to @user
    else
      render :index   
    end
  end

  def destroy
    @user.destroy
    flash[:success] = "#{@user.name}のデータを削除しました。"
    redirect_to users_url
  end

  def edit_basic_info
    if current_user.admin?
      @user = User.find(params[:id])
    end
  end

  def update_basic_info
    if @user.update_attributes(basic_info_params)
      flash[:success] = "#{@user.name}の基本情報を更新しました。"
    else
      flash[:danger] = "#{@user.name}の更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
    end
    redirect_to users_url
  end
  
  
  
  
  private

    def user_params
      params.require(:user).permit(:name, :email, :department, :designated_work_end_time, :designated_work_start_time, :password, :password_confirmation)
    end

    def basic_info_params
      params.require(:user).permit(:department, :basic_time, :work_time)
    end
    
    
    
    def search
    #Viewのformで取得したパラメータをモデルに渡す
    @users = User.search(params[:search])
    end
end