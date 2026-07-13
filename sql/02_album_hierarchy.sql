CREATE OR REPLACE FUNCTION public.album_asset_propagate()
RETURNS TRIGGER AS $$
DECLARE
    album_name text;
    names text[];
    target_name text;
    target_album_id uuid;
    original_owner_id uuid;
BEGIN
    -- Wrap everything in a top-level block to catch any unexpected failures
    BEGIN
        -- Get album name
        SELECT "albumName" INTO album_name
        FROM public.album
        WHERE id = NEW."albumId";

        IF album_name IS NOT NULL AND position('|' in album_name) > 0 THEN
            
            -- Get the owner of the original album from album_user
            SELECT "userId" INTO original_owner_id
            FROM public.album_user
            WHERE "albumId" = NEW."albumId"
              AND role = 'owner'::album_user_role_enum
            LIMIT 1;

            -- Only proceed if an owner was successfully resolved
            IF original_owner_id IS NOT NULL THEN
                names := string_to_array(album_name, '|');

                FOREACH target_name IN ARRAY names LOOP
                    target_name := btrim(target_name);

                    -- Find target album with the same name owned by the same user
                    SELECT a.id INTO target_album_id
                    FROM public.album a
                    JOIN public.album_user au ON a.id = au."albumId"
                    WHERE a."albumName" = target_name
                      AND au."userId" = original_owner_id
                      AND au.role = 'owner'::album_user_role_enum
                    LIMIT 1;

                    IF target_album_id IS NOT NULL AND target_album_id <> NEW."albumId" THEN
                        -- Inner block to safely isolate conflicts per target album
                        BEGIN
                            INSERT INTO public.album_asset("albumId", "assetId")
                            VALUES (target_album_id, NEW."assetId")
                            ON CONFLICT DO NOTHING;
                        EXCEPTION WHEN OTHERS THEN
                            -- Keeps a single bad target from breaking loop propagation to other targets
                            RAISE WARNING 'Propagation failed for target album %: %', target_name, SQLERRM;
                        END;
                    END IF;
                -- End loop
                END LOOP;
            END IF;
        END IF;

    EXCEPTION WHEN OTHERS THEN
        -- Catch-all for any error (e.g., missing enum, missing table columns, etc.)
        -- RAISE WARNING logs the error to PostgreSQL logs without crashing the transaction
        RAISE WARNING 'Album asset propagation skipped due to error: %', SQLERRM;
    END;

    -- This always executes, ensuring the original insert succeeds
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;