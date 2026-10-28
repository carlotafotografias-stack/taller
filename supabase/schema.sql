-- =============================================================
--  TALLER · Base de datos en Supabase
--  Pegar este script completo en Supabase › SQL Editor › New query
--  y ejecutarlo con "Run". Se puede volver a correr sin problemas.
-- =============================================================

-- ---------- Limpieza (permite volver a ejecutar el script) ----------
drop function if exists public.reservar(uuid, int);
drop table if exists public.resenas cascade;
drop table if exists public.reservas cascade;
drop table if exists public.fechas cascade;
drop table if exists public.talleres cascade;
drop table if exists public.perfiles cascade;
drop function if exists public.crear_perfil() cascade;

-- ---------- Tablas ----------

-- Perfil de cada usuario (se crea solo al registrarse)
create table public.perfiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  nombre      text not null default '',
  intereses   text[] not null default '{}',
  creado_en   timestamptz not null default now()
);

-- Talleres disponibles
create table public.talleres (
  id                    uuid primary key default gen_random_uuid(),
  titulo                text not null,
  categoria             text not null check (categoria in ('ceramica', 'pintura', 'yoga', 'sonido', 'fotografia')),
  descripcion           text not null,
  lugar                 text not null,
  zona                  text not null,
  precio                int  not null check (precio >= 0),
  duracion_min          int  not null,
  nivel                 text not null default 'Inicial',
  materiales_incluidos  boolean not null default true,
  docente               text not null,
  destacado             boolean not null default false
);

-- Fechas y cupos de cada taller
create table public.fechas (
  id               uuid primary key default gen_random_uuid(),
  taller_id        uuid not null references public.talleres (id) on delete cascade,
  inicio           timestamptz not null,
  cupo_total       int not null check (cupo_total > 0),
  cupo_disponible  int not null check (cupo_disponible >= 0)
);

-- Reservas de los usuarios
create table public.reservas (
  id          uuid primary key default gen_random_uuid(),
  usuario_id  uuid not null references auth.users (id) on delete cascade,
  taller_id   uuid not null references public.talleres (id) on delete cascade,
  fecha_id    uuid not null references public.fechas (id) on delete cascade,
  cantidad    int  not null check (cantidad between 1 and 10),
  total       int  not null,
  estado      text not null default 'confirmada',
  codigo      text not null default upper(substr(md5(random()::text), 1, 8)),
  creado_en   timestamptz not null default now()
);

-- Reseñas (una por usuario y taller)
create table public.resenas (
  id          uuid primary key default gen_random_uuid(),
  usuario_id  uuid not null references auth.users (id) on delete cascade,
  taller_id   uuid not null references public.talleres (id) on delete cascade,
  puntaje     int  not null check (puntaje between 1 and 5),
  comentario  text not null default '',
  creado_en   timestamptz not null default now(),
  unique (usuario_id, taller_id)
);

-- ---------- Perfil automático al registrarse ----------
create function public.crear_perfil()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.perfiles (id, nombre, intereses)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'nombre', ''),
    coalesce(
      array(select jsonb_array_elements_text(new.raw_user_meta_data -> 'intereses')),
      '{}'
    )
  );
  return new;
end;
$$;

create trigger al_crear_usuario
  after insert on auth.users
  for each row execute function public.crear_perfil();

-- ---------- Reservar descontando cupos de forma segura ----------
create function public.reservar(p_fecha_id uuid, p_cantidad int)
returns public.reservas
language plpgsql
security definer set search_path = public
as $$
declare
  v_fecha   public.fechas;
  v_precio  int;
  v_reserva public.reservas;
begin
  if auth.uid() is null then
    raise exception 'Tenés que iniciar sesión para reservar';
  end if;

  select * into v_fecha from public.fechas where id = p_fecha_id for update;
  if not found then
    raise exception 'La fecha no existe';
  end if;
  if v_fecha.inicio < now() then
    raise exception 'Esa fecha ya pasó';
  end if;
  if p_cantidad < 1 or p_cantidad > v_fecha.cupo_disponible then
    raise exception 'No hay cupos suficientes';
  end if;

  select precio into v_precio from public.talleres where id = v_fecha.taller_id;

  update public.fechas
     set cupo_disponible = cupo_disponible - p_cantidad
   where id = p_fecha_id;

  insert into public.reservas (usuario_id, taller_id, fecha_id, cantidad, total)
  values (auth.uid(), v_fecha.taller_id, p_fecha_id, p_cantidad, v_precio * p_cantidad)
  returning * into v_reserva;

  return v_reserva;
end;
$$;

grant execute on function public.reservar(uuid, int) to authenticated;

-- ---------- Seguridad (Row Level Security) ----------
alter table public.perfiles enable row level security;
alter table public.talleres enable row level security;
alter table public.fechas   enable row level security;
alter table public.reservas enable row level security;
alter table public.resenas  enable row level security;

-- Talleres y fechas: cualquiera puede verlos
create policy "talleres visibles" on public.talleres for select using (true);
create policy "fechas visibles"   on public.fechas   for select using (true);

-- Perfil: cada usuario ve y edita solo el suyo
create policy "ver mi perfil"    on public.perfiles for select using (auth.uid() = id);
create policy "editar mi perfil" on public.perfiles for update using (auth.uid() = id);

-- Reservas: cada usuario ve solo las suyas (se crean con la función reservar)
create policy "ver mis reservas" on public.reservas for select using (auth.uid() = usuario_id);

-- Reseñas: todos las leen, cada usuario escribe las suyas
create policy "resenas visibles" on public.resenas for select using (true);
create policy "crear mi resena"  on public.resenas for insert with check (auth.uid() = usuario_id);
create policy "editar mi resena" on public.resenas for update using (auth.uid() = usuario_id);

-- ---------- Datos de ejemplo ----------
insert into public.talleres (titulo, categoria, descripcion, lugar, zona, precio, duracion_min, nivel, materiales_incluidos, docente, destacado) values
('Torno para principiantes', 'ceramica',
 'Aprendé a centrar el barro y levantar tu primera pieza en el torno. Grupos chicos, mate y música. Tu pieza se hornea y la retirás a las dos semanas.',
 'Barro Estudio', 'Chacras de Coria', 18000, 120, 'Inicial', true, 'Lucía Ferrer', true),
('Yoga al atardecer', 'yoga',
 'Una práctica suave de hatha yoga al aire libre para cerrar el día. Traé tu mat y abrigo liviano; terminamos con una relajación guiada.',
 'Parque General San Martín', 'Ciudad', 9000, 75, 'Todos los niveles', false, 'Martín Quiroga', true),
('Acuarela botánica', 'pintura',
 'Observamos hojas y flores de estación y las pintamos con acuarela. Técnicas de capas, transparencias y mezcla de color.',
 'Casa Ocre', 'Ciudad', 14000, 150, 'Inicial', true, 'Valentina Sosa', true),
('Baño de sonido', 'sonido',
 'Una experiencia de relajación profunda con cuencos tibetanos, gong y tambores oceánicos. Solo tenés que recostarte y escuchar.',
 'Espacio Lumbre', 'Godoy Cruz', 12000, 60, 'Todos los niveles', true, 'Julieta Arce', false),
('Fotografía analógica', 'fotografia',
 'Salimos a recorrer la ciudad con cámaras de rollo. Aprendés exposición, encuadre y cómo cargar una cámara de 35 mm.',
 'Punto Foco', 'Ciudad', 16000, 180, 'Inicial', true, 'Tomás Gil', false),
('Modelado a mano', 'ceramica',
 'Técnicas de pellizco, rollos y planchas para crear tazas y cuencos sin torno. Ideal si nunca tocaste arcilla.',
 'Barro Estudio', 'Chacras de Coria', 15000, 120, 'Inicial', true, 'Lucía Ferrer', false);

-- Para cada taller, tres fechas en las próximas semanas
insert into public.fechas (taller_id, inicio, cupo_total, cupo_disponible)
select t.id,
       date_trunc('day', now()) + (d.dias || ' days')::interval + h.hora,
       8, 8
from public.talleres t
cross join (values (3), (10), (17)) as d(dias)
cross join lateral (
  select case t.categoria
           when 'yoga'   then interval '19 hours'
           when 'sonido' then interval '20 hours'
           else interval '10 hours'
         end as hora
) h;
