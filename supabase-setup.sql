create table if not exists public.product_prices (
  product_name text not null,
  weight text not null,
  price_inr integer not null check (price_inr >= 0),
  updated_at timestamptz not null default now(),
  primary key (product_name, weight)
);

insert into public.product_prices (product_name, weight, price_inr)
values
  ('Daybreak', '250 g', 399),
  ('Daybreak', '500 g', 699),
  ('Slow Sunday', '250 g', 449),
  ('Slow Sunday', '500 g', 799),
  ('Little Wild', '250 g', 499),
  ('Little Wild', '500 g', 849)
on conflict (product_name, weight) do nothing;

create table if not exists public.price_admins (
  user_id uuid primary key references auth.users (id) on delete cascade
);

alter table public.product_prices enable row level security;
alter table public.price_admins enable row level security;

drop policy if exists "Anyone can read product prices" on public.product_prices;
create policy "Anyone can read product prices"
  on public.product_prices for select
  to anon, authenticated
  using (true);

drop policy if exists "Price admins can update product prices" on public.product_prices;
create policy "Price admins can update product prices"
  on public.product_prices for update
  to authenticated
  using (
    exists (
      select 1 from public.price_admins
      where price_admins.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.price_admins
      where price_admins.user_id = (select auth.uid())
    )
  );

drop policy if exists "Admins can read their own access" on public.price_admins;
create policy "Admins can read their own access"
  on public.price_admins for select
  to authenticated
  using (user_id = (select auth.uid()));

grant select on public.product_prices to anon, authenticated;
grant update on public.product_prices to authenticated;
grant select on public.price_admins to authenticated;

-- After creating an admin user in Supabase Authentication, grant that user
-- access by replacing the UUID below with the user's ID and running:
-- insert into public.price_admins (user_id) values ('USER-UUID-HERE');
