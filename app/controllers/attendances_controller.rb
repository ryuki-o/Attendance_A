class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month, :month_approval]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: [:edit_one_month, :month_approval]

  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"

  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: Time.current.change(sec: 0))
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current.change(sec: 0))
        flash[:info] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end

  def edit_one_month
  end

  def update_one_month
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        attendance.update_attributes!(item)
        attendance.attributes = item
        attendance.save!(context: :attendance_update)
      end
    end
    flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end
  
  def edit_overwork_request
    @day = Date.parse(params[:day])
    @user = User.find(params[:id])
    @attendance = @user.attendances.find_by(worked_on: @day)
  end
  
  def update_overwork_request
    @day = Date.parse(params[:day])
    @user = User.find(params[:id])
    @attendance = @user.attendances.find_by(worked_on: @day)
    @attendance.update_attributes(overwork_params)
    flash[:success] = "残業を申請しました。"
    redirect_to @user
    
   if params[:attendance][:scheduled_end_time].blank? && params[:attendance][:business_process].blank?
     flash[:danger] = "終了予定時間及び業務処理内容が空です。"
     redirect_to user_url(@user) and return
   end
   
   if params[:attendance][:scheduled_end_time].blank?
     flash[:danger] = "終了予定時間が空です。"
     redirect_to user_url(@user) and return
   end
   
   if params[:attendance][:business_process].blank?
     flash[:danger] = "業務処理内容が空です。"
     redirect_to user_url(@user) and return
   end
   
  end
  
  # 残業申請承認モーダル
  def edit_superior_announcement
    @user = User.find(params[:id])
    @attendance = Attendance.find(params[:id])
    @attendances = Attendance.where(confirmation: '申請中', instructor_confirmation: @user.id).order(:user_id).group_by(&:user_id)
  end
  
  
  def update_superior_announcement
    @user = User.find(params[:id])
    @attendance = Attendance.find(params[:id])
    # @attendances = Attendance.where(confirmation: '承認', instructor_confirmation: @user.id).order(:user_id).group_by(&:user_id)
    debugger
    
    if @attendance.confirmation = "申請中"
      flash[:danger] = "指示者確認が申請中のままです。"
      redirect_to user_url(@user) and return
    end
    
    if @attendance.confirmation = "承認"
      @attendance.save!
      flash[:success] = "#{@attendance.instructor_confirmation}による残業承認完了しました。"
      redirect_to user_url(@user) and return
    end
    
    if @attendance.update_attributes(overwork_params)
      # 更新成功時の処理
      flash[:success] = "#{@user.name}の残業申請は承認されました。"
      redirect_to user_url(@user)
    else
      # 更新失敗時の処理
      flash[:danger] = "#{@user.name}の申請が失敗しました。" + @user.errors.full_messages.join(" 、")
      redirect_to user_url(@user)
    end
      
  end
  
  # 勤怠申請モーダルの確認ボタン
  def month_approval
    @user = User.find(params[:id])
    @attendance = Attendance.find(params[:id])
    @first_day = @attendance.worked_on.beginning_of_month
    @last_day = @first_day.end_of_month
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on) #order日付順に並び替える、..は～から～まで
    @worked_sum = @attendances.where.not(started_at: nil).count
  end
  
  
  private

    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :note])[:attendances]
    end
    
    def overwork_params
      params.require(:attendance).permit(:scheduled_end_time, :next_day, :overtime_status, :business_process, :confirmation, :change, :instructor_confirmation)
    end
    
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end  
    end
end