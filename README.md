# Rails Example

Example Rails 7.1 app which can be deployed to the Reclaim the Stack platform. It's a blog!

## Deployment

After configuring [k](https://github.com/reclaim-the-stack/k) you can build and push the Dockerfile using `k build-and-push`. If you don't want to build it yourself you can also just reference one of the official builds at [Docker Hub](https://hub.docker.com/r/reclaimthestack/rails-example/tags).

We will assume that you have the Reclaim the Stack platform installed and [k](https://github.com/reclaim-the-stack/k) configured and that you're having your gitops repository as working directory.

Start by creating the application skeleton:

```
k generate application rails-example
```

Next add a web deployment for the Rails server:

```
k generate deployment rails-example
```

Pay careful attention to the output and add configuration to `applications/rails-example/values.yaml` and `cloudflared` ingress as adviced. For the `image:` configuration make sure to reference the docker image you pushed earlier or one of the builds from our [Docker Hub](https://hub.docker.com/r/reclaimthestack/rails-example/tags).

While creating the secret with `k secrets:create rails-example` make sure to include a random string for the `SECRET_KEY_BASE` environment variable.

If you commit and push your changes you should now be able to access the application but will fail with an error due to Postgres being missing (use `k logs rails-example` or `k logs:search rails-example` to observe the error messages).

Add a resource and select Postgres at the prompt:

```
k generate resource rails-example
```

Again follow the output carefully. After this step your deployment should get access to Postgres via the `DATABASE_URL` environment variable but will again hit an error, this time because we haven't loaded the database schema yet.

Load the schema with:

```
k run rails-example bin/rails db:schema:load
```

You should now be able to browse the application but will hit an error due to a missing Redis database if you try to create a Post or a Link.

Let's add another resource, select Redis at the prompt:

```
k generate resource rails-example
```

Now you can create posts and links. But links will not resolve until we have added a Sidekiq deployment to take care of our background jobs.

Let's add another deployment, select Sidekiq at the prompt:

```
k generate deployment rails-example
```

After deploying Sidekiq your links should resolve.

As a final step we will add Elasticsearch to support the Search functionality.

Add a resource, selecting Elasticsearch at the prompt:

```
k generate resource rails-example
```

Note that if you do a single replica Elasticsearch deployment your application will end up in "degraded" state in ArgoCD due to Elasticsearch requiring at least two replicas per index by default. It looks worse than it is, so feel free to ignore it. But if you want a fully green Elasticsearch deployment you either have to increase the replicas to at least 2 or configure all indexes on the Elasticsearch server to [assume 0 replication](https://discuss.elastic.co/t/change-number-of-replicas-to-0-on-existing-indices/141622).

After pushing this you should now have access to the Search functionality. However if you had already created posts and links before adding Elasticsearch they will not have been indexed yet. A simple way to trigger indexing for existing records is to open up a Rails console and update the existing records via `#touch`:

```
k console rails-example

# inside the rails console:
Post.find_each(&:touch)
Link.find_each(&:touch)
```

