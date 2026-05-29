import os

directory = "modular/world_edit/code/generators/building_layout/pipeline/stages"

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith(".dm"):
            filepath = os.path.join(root, file)
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
            
            new_content = content.replace(
                'var/datum/world_edit_generator/building_layout/generator = GLOB.world_edit_generator_catalog["building_layout"]', 
                'var/datum/world_edit_generator/building_layout/generator = context.generator'
            )
            
            if content != new_content:
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(new_content)
                print(f"Updated {filepath}")
