module TheComments
  module AdminController
    extend ActiveSupport::Concern

    included do
      include TheComments::ViewToken
    end

    def index
      @comments = ::Comment.with_state(:published).recent.page(params[:page])
      render comment_template(:index)
    end

    def edit_by_author
      @comment = current_user.comments.find(params[:id])
      if @comment.update_by_author(params[:comment])
        render layout: false, partial: comment_partial(:comment_body), locals: { comment: @comment }
      else
        render json: { errors: @comment.errors.full_messages }
      end
    end

    # Methods for admin
    %w[published deleted].each do |state|
      define_method "total_#{state}" do
        @comments = ::Comment.with_state(state).recent.page(params[:page])
        render comment_template(:manage)
      end
    end

    def total_spam
      @comments = ::Comment.where(spam: true).recent.page(params[:page])
      render comment_template(:manage)
    end

    def update
      @comment = ::Comment.find(params[:id])
      @comment.update_attributes!(patch_comment_params)
      render(layout: false, partial: comment_partial(:comment_body), locals: { comment: @comment })
    end

    %w[draft published deleted].each do |state|
      define_method "to_#{state}" do
        ::Comment.find(params[:id]).try "to_#{state}"
        render nothing: true
      end
    end

    def to_spam
      comment = ::Comment.find(params[:id])
      comment.to_spam
      comment.to_deleted
      render nothing: true
    end

    private

    def comment_template template
      { template: "the_comments/#{TheComments.config.template_engine}/#{template}" }
    end

    def comment_partial partial
      "the_comments/#{TheComments.config.template_engine}/#{partial}"
    end

    def denormalized_fields
      title = @commentable.commentable_title
      url   = @commentable.commentable_url
      @commentable ? { commentable_title: title, commentable_url: url } : {}
    end

    def request_data_for_comment
      r = request
      { ip: r.ip, referer: CGI::unescape(r.referer  || 'direct_visit'), user_agent: r.user_agent }
    end

    def comment_params
      params
        .require(:comment)
        .permit(:title, :contacts, :raw_content, :parent_id)
        .merge(denormalized_fields)
        .merge(request_data_for_comment)
        .merge(tolerance_time: params[:tolerance_time].to_i)
        .merge(user: current_user, view_token: comments_view_token)
    end

    def patch_comment_params
      params
        .require(:comment)
        .permit(:title, :contacts, :raw_content, :parent_id)
    end

    def cookies_required
      if cookies[:the_comment_cookies] != TheComments::COMMENTS_COOKIES_TOKEN
        @errors << [t('the_comments.cookies'), t('the_comments.cookies_required')].join(': ')
      end
    end
  end
end