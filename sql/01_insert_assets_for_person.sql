CREATE OR REPLACE FUNCTION public.insert_assets_for_person(
    person_id uuid)
    RETURNS integer
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    inserted_count INTEGER;
BEGIN
    WITH inserted_rows AS (
        INSERT INTO album_asset ("albumId", "assetId")
        SELECT ap."albumId", af."assetId"
        FROM albums_persons ap
        INNER JOIN asset_face af
        ON af."personGroupId" = ap."personId"
        WHERE ap."personId" = person_id
          AND NOT EXISTS (
              SELECT 1 
              FROM album_asset aa 
              WHERE aa."albumId" = ap."albumId" 
                AND aa."assetId" = af."assetId"
          )
        RETURNING 1
    )
    SELECT COUNT(*) INTO inserted_count FROM inserted_rows;
    RETURN inserted_count;
END;
$BODY$;

ALTER FUNCTION public.insert_assets_for_person(uuid)
    OWNER TO postgres;