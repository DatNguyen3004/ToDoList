create table if not exists public.tdl_tasks (
  user_id uuid not null references auth.users(id) on delete cascade,
  id text not null,
  title text not null default '',
  description text,
  rich_text_json text,
  drawing_json text,
  image_paths jsonb not null default '[]'::jsonb,
  content_type text not null check (content_type in ('text', 'drawing', 'image')),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  due_date timestamptz,
  is_completed boolean not null default false,
  is_deleted boolean not null default false,
  primary key (user_id, id)
);

alter table public.tdl_tasks enable row level security;

create policy "Người dùng đọc công việc của mình"
on public.tdl_tasks for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Người dùng tạo công việc của mình"
on public.tdl_tasks for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "Người dùng sửa công việc của mình"
on public.tdl_tasks for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "Người dùng xóa công việc của mình"
on public.tdl_tasks for delete
to authenticated
using ((select auth.uid()) = user_id);

insert into storage.buckets (id, name, public)
values ('task-images', 'task-images', false)
on conflict (id) do update set public = false;

create policy "Người dùng xem ảnh của mình"
on storage.objects for select
to authenticated
using (
  bucket_id = 'task-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Người dùng tải ảnh của mình"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'task-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Người dùng sửa ảnh của mình"
on storage.objects for update
to authenticated
using (
  bucket_id = 'task-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'task-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Người dùng xóa ảnh của mình"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'task-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
