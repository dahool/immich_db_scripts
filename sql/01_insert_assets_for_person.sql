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
        ON CONFLICT ("albumId", "assetId") DO NOTHING
        RETURNING 1
    )
    SELECT COUNT(*) INTO inserted_count FROM inserted_rows;
    RETURN inserted_count;
END;
$BODY$;

ALTER FUNCTION public.insert_assets_for_person(uuid)
    OWNER TO postgres;

