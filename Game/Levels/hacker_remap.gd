@tool
extends TileMapLayer

@export_category("Tile Source Remap")
@export var remap_source_1_to_0: bool = false:
    set(value):
        if value:
            print("Remapping A")
            _remap_source(1, 0)
        remap_source_1_to_0 = false

@export var duplicate_source_1: bool = false:
    set(value):
        print("A")
        if value:
            _duplicate_source(1)
        duplicate_source_1 = false




func _remap_source(from_source: int, to_source: int) -> void:
    print("Remapping B")
    var cells := get_used_cells_by_id(from_source)

    print("Remapping %d cells: source %d -> source %d" % [
        cells.size(),
        from_source,
        to_source
    ])

    for cell in cells:
        var atlas_coords := get_cell_atlas_coords(cell)
        var alternative := get_cell_alternative_tile(cell)

        set_cell(
            cell,
            to_source,
            atlas_coords,
            alternative
        )

    update_internals()

    print("Remap complete.")


func _duplicate_source(source_id: int) -> void:
    print("A")
    if tile_set == null:
        push_error("No TileSet assigned.")
        return

    print("B")
    var source := tile_set.get_source(source_id)
    if source == null:
        push_error("Source %d not found." % source_id)
        return

    print("C")
    var duplicatedSource := source.duplicate(true)

    print("D")
    var new_source_id := tile_set.add_source(duplicatedSource)

    print("Duplicated source %d -> source %d" % [source_id,new_source_id])
