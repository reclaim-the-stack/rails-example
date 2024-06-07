class PostsController < ApplicationController
  before_action :enable_caching, only: %i[index show new edit]
  skip_before_action :verify_authenticity_token

  # GET /posts
  def index
    @posts = Post.all
  end

  # GET /posts/1
  def show
    @post = Post.find(params[:id])
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
    @post = Post.find(params[:id])
  end

  # POST /posts
  def create
    @post = Post.new(post_params)

    if @post.save
      CachedUrl.expire_by_tags(["posts:all"])
      redirect_to post_url(@post, nocache: true), notice: "Post was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /posts/1
  def update
    @post = Post.find(params[:id])

    if @post.update(post_params)
      CachedUrl.expire_by_tags(["posts:all", "posts:#{@post.id}"])
      redirect_to post_url(@post, nocache: true), notice: "Post was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /posts/1
  def destroy
    post = Post.find(params[:id])

    post.destroy!

    CachedUrl.expire_by_tags(["posts:all", "posts:#{post.id}"])

    redirect_to posts_url(nocache: true), notice: "Post was successfully destroyed.", status: :see_other
  end

  private

  def post_params
    params.require(:post).permit(:title, :body)
  end

  def enable_caching
    return if params.key?(:nocache)

    # don't cache cookies (note: Cloudflare won't cache responses with cookies)
    request.session_options[:skip] = true

    tags = action_name == "index" ? ["section:posts", "posts:all"] : ["section:posts", "posts:#{params[:id]}"]

    CachedUrl.upsert({ url: request.url, tags:, expires_at: 1.hour.from_now }, unique_by: :url)
    expires_in 1.hour, public: true
  end
end
