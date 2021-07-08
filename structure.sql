CREATE TABLE users (
  id bigserial primary key,
  email character varying not null,
  created_at timestamp default NOW(),
  updated_at timestamp default NOW()
);

CREATE TABLE todos (
  id bigserial primary key,
  user_id bigint not null,
  description character varying not null,
  completed_at timestamp,
  created_at timestamp default NOW(),
  updated_at timestamp default NOW(),
  foreign key (user_id) references users (id)
);

CREATE TABLE tags (
  id bigserial primary key,
  user_id bigint not null,
  description character varying not null,
  created_at timestamp default NOW(),
  updated_at timestamp default NOW(),
  foreign key (user_id) references users (id)
);

CREATE TABLE taggings (
  id bigserial primary key,
  todo_id bigint not null,
  tag_id bigint not null,
  foreign key (todo_id) references todos (id),
  foreign key (tag_id) references tags (id),
  unique (todo_id, tag_id)
);

CREATE TABLE recommended_todos (
  id bigserial primary key,
  todo_id bigint not null,
  user_id bigint not null,
  foreign key (todo_id) references todos (id),
  foreign key (user_id) references users (id),
  unique (todo_id, user_id)
);
