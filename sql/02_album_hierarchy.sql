CREATE OR REPLACE FUNCTION public.album_asset_propagate()
RETURNS TRIGGER AS $$
DECLARE
    album_name text;
    names text[];
    target_name text;
    target_album_id uuid;
    original_owner_id uuid;
BEGIN
    -- Obtener nombre y owner del álbum original
    SELECT "albumName", "ownerId"
    INTO album_name, original_owner_id
    FROM public.album
    WHERE id = NEW."albumId";

    IF album_name IS NULL OR position('|' in album_name) = 0 THEN
        RETURN NEW;
    END IF;

    names := string_to_array(album_name, '|');

    FOREACH target_name IN ARRAY names LOOP
        target_name := btrim(target_name);

        -- Buscar álbum destino con mismo nombre y mismo owner
        SELECT id INTO target_album_id
        FROM public.album
        WHERE "albumName" = target_name
          AND "ownerId" = original_owner_id
        LIMIT 1;

        IF target_album_id IS NOT NULL AND target_album_id <> NEW."albumId" THEN
            BEGIN
                INSERT INTO public.album_asset("albumId", "assetId")
                VALUES (target_album_id, NEW."assetId")
                ON CONFLICT DO NOTHING;
            EXCEPTION WHEN unique_violation THEN
                NULL;
            END;
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION public.album_asset_propagate()
    OWNER TO postgres;

CREATE OR REPLACE TRIGGER album_asset_propagate_trigger
AFTER INSERT ON public.album_asset
FOR EACH ROW
EXECUTE FUNCTION public.album_asset_propagate();
