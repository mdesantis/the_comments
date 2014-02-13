# coding: UTF-8
# DOC:
# We use Helper Methods for tree building,
# because it's faster than View Templates and Partials

# SECURITY note
# Prepare your data on server side for rendering
# or use h.html_escape(node.content)
# for escape potentially dangerous content
module RenderCommentsTreeHelper
  module Render
    class << self
      attr_accessor :h, :options

      # Main Helpers
      def controller
        @options[:controller]
      end

      def t *args
        controller.t *args
      end

      # Render Helpers
      def visible_draft?
        controller.try(:comments_view_token) == @comment.view_token
      end

      def moderator?
        controller.try(:current_user).try(:comments_moderator?, @comment)
      end

      # Render Methods
      def render_node(h, options)
        @h, @options     = h, options
        @comment         = options[:node]
        @max_reply_depth = options[:max_reply_depth] || TheComments.config.max_reply_depth
        published_comment
      end

      def published_comment
        "<li>
          <div id='comment_#{@comment.anchor}' class='comment #{@comment.state}' data-comment-id='#{@comment.to_param}' data-secs='#{seconds_left}'>
            <div>
              #{ avatar }
              #{ userbar }
              <div class='cbody'>#{ @comment.content }</div>
              #{ reply }
              #{ edit_by_author }
              #{ request_delete }
            </div>
          </div>

          <div class='form_holder'></div>
          #{ children }
        </li>"
      end

      def avatar
        "<div class='userpic'>
          <img src='#{ @comment.avatar_url }' alt='userpic' />
          #{ controls }
        </div>"
      end

      def userbar
        anchor = h.link_to('#', "#comment_#{@comment.anchor}")
        title  = @comment.author.username
        "<div class='userbar'>#{ title } #{ anchor }</div>"
      end

      def edit_by_author
        if @comment.editable_by_author?
          h.link_to t('the_comments.edit_by_author', secs: seconds_left).html_safe, h.edit_comment_url(@comment), class: :edit
        end
      end

      def seconds_left
        diff = 4*60 - (Time.zone.now - @comment.created_at)
        diff > 0 ? diff.to_i : 0
      end

      def moderator_controls
        if moderator?
          h.link_to(t('the_comments.edit'), h.edit_comment_url(@comment), class: :edit)
        end
      end

      def reply
        if @comment.depth < (@max_reply_depth - 1) && !comment_author_is_current_user?
          "<p class='reply'><a href='#' class='reply_link'>#{ t('the_comments.reply') }</a>"
        end
      end

      def controls
        "<div class='controls'>#{ moderator_controls }</div>"
      end

      def children
        "<ol class='nested_set'>#{ options[:children] }</ol>"
      end

      def request_delete
        if comment_author_is_current_user? and !@comment.delete_requested?
          h.content_tag :span do
            h.link_to t('the_comments.delete_request'), h.delete_request_comment_path(@comment), class: 'delete_request'
          end
        end
      end

      def comment_author_is_current_user?
        current_user && current_user == @comment.author
      end

      def current_user
        controller.current_user
      end
    end
  end
end