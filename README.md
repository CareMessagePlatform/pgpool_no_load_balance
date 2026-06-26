# PgpoolNoLoadBalance

This gem lets you opt individual queries out of read/write load balancing so they run against the primary, when your app sits behind a query router such as [Pgpool-II](https://www.pgpool.net/docs/latest/en/html/runtime-config-load-balancing.html) or [PgDog](https://docs.pgdog.dev/features/load-balancer/manual-routing/).

Both routers support a per-query SQL comment that pins a query to the primary. This gem prepends that comment for you. The exact comment depends on which router(s) you target:

| Backend          | Comment emitted             |
| ---------------- | --------------------------- |
| `:pgpool` (default) | `/*NO LOAD BALANCE*/`       |
| `:pgdog`         | `/* pgdog_role: primary */` |

For Pgpool-II, a leading comment disables load balancing for the query and sends it to the primary node. For PgDog, the comment routes the query to the primary via [manual routing](https://docs.pgdog.dev/features/load-balancer/manual-routing/).

## Installation

Add this line to your application's Gemfile:

```rb
gem 'pgpool_no_load_balance'
```

And then execute:

```console
$ bundle install
```

## Backend configuration

The gem prepends a primary-pinning SQL comment to flagged queries. Which
comment(s) it emits is configured via `PgpoolNoLoadBalance.backends`, which
defaults to `[:pgpool]` (so existing apps need no change):

```rb
# config/initializers/pgpool_no_load_balance.rb
PgpoolNoLoadBalance.backends = [:pgpool]            # /*NO LOAD BALANCE*/
PgpoolNoLoadBalance.backends = :pgdog               # /* pgdog_role: primary */
PgpoolNoLoadBalance.backends = [:pgpool, :pgdog]    # both, pgpool first
PgpoolNoLoadBalance.backends = "pgpool,pgdog"       # comma-separated string also accepted
```

When both backends are configured, the comments are emitted adjacent and
leading — `/*NO LOAD BALANCE*/ /* pgdog_role: primary */ SELECT …` — which pins
the query to the primary on either router (useful during a pgpool → pgdog
migration). Emission order is always pgpool-then-pgdog regardless of how you
order the input. An unknown or empty backend raises `ArgumentError`. The
singular `PgpoolNoLoadBalance.backend = :pgdog` is also accepted as a
convenience for a single backend.

**Deployment prerequisites for the comment hints to take effect:**

- Pgpool-II: `allow_sql_comments` must be `off` (the default).
- PgDog: comment-based manual routing / the query parser must be enabled.

## Usage

### no_load_balance method

Using the `no_load_balance` method adds the configured backend comment(s) to the SQL.

```rb
irb(main):001:0> User.no_load_balance.all
  /*NO LOAD BALANCE*/ SELECT "users".* FROM "users" LIMIT $1  [["LIMIT", 11]]
```

`pgpool_nlb` remains available as an alias of `no_load_balance` for backwards compatibility:

```rb
irb(main):001:0> User.pgpool_nlb.all
  /*NO LOAD BALANCE*/ SELECT "users".* FROM "users" LIMIT $1  [["LIMIT", 11]]
```

### blocks

Use a `PgpoolNoLoadBalance.force` block to force all read queries inside the block to run pinned to the primary:

```rb
irb(main):001:0> PgpoolNoLoadBalance.force { User.all }
  /*NO LOAD BALANCE*/ SELECT "users".* FROM "users" LIMIT $1  [["LIMIT", 11]]
```

### unscope

You can remove the scope with `unscope`. Either symbol works:

```rb
irb(main):001:0> user_relation = User.where(name: 'elengine').no_load_balance

irb(main):002:0> user_relation.unscope(:no_load_balance).order(:id).limit(3)
  SELECT "users".* FROM "users" WHERE "users"."name" = $1 ORDER BY "users"."id" ASC LIMIT $2  [["name", "elengine"], ["LIMIT", 3]]

irb(main):003:0> user_relation.unscope(:pgpool_nlb)  # legacy symbol, same effect
```

### Arbitrary SQL execution

Using the `no_load_balance` option of the `execute` method adds the comment(s) to the SQL. The legacy `pgpool_nlb` keyword is still accepted.

```rb
irb(main):001:0> ActiveRecord::Base.connection.execute('SELECT 1')
  SELECT 1

irb(main):002:0> ActiveRecord::Base.connection.execute('SELECT 1', no_load_balance: true)
  /*NO LOAD BALANCE*/ SELECT 1
```

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/elengine/pgpool_no_load_balance>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/elengine/pgpool_no_load_balance/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PgpoolNoLoadBalance project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/elengine/pgpool_no_load_balance/blob/master/CODE_OF_CONDUCT.md).
