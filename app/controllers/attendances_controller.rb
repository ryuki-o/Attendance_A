class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: :edit_one_month

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
  end
  
  # 残業申請承認モーダル
  def edit_superior_announcement
    @user = User.find(params[:id])
    @attendances = Attendance.where(confirmation: '申請中', instructor_confirmation: @user.id).order(:user_id).group_by(&:user_id)
  end
  
  
  def update_superior_announcement
    ActiveRecord::Base.transaction do
      @overtime_status = Attendance.where(overtime_status: "申請中").count
      @overtime_status1 = Attendance.where(overtime_status: "承認").count
      @overtime_status2 = Attendance.where(overtime_status: "否認").count
      @overtime_status3 = Attendance.where(overtime_status: "なし").count
      @user = User.find(params[:user_id])
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        attendance.update_attributes!(item)
      end
    end
    flash[:success] = "残業申請→申請中を#{@overtime_status}件、承認を#{@overtime_status1}件、否認を#{@overtime_status2}件、なしを#{@overtime_status3}件送信しました。"
    redirect_to user_url(@user)
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to user_url(@user)
  end
  
  
  private

    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :note])[:attendances]
    end
    
    def overwork_params
      params.require(:attendance).permit(:scheduled_end_time, :next_day, :business_process, :confirmation, :instructor_confirmation)
    end
    
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end  
    end
end