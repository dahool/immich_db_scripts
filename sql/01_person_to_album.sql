
CREATE OR REPLACE FUNCTION public.person_assets_to_album_function()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
    IF NEW."personId" IS NOT NULL THEN
        PERFORM insert_assets_for_person(NEW."personId");
    END IF;
    RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.person_assets_to_album_function()
    OWNER TO postgres;
    
CREATE OR REPLACE TRIGGER person_assets_to_album
    AFTER INSERT OR UPDATE 
    ON public.asset_face
    FOR EACH ROW
    EXECUTE FUNCTION public.person_assets_to_album_function();