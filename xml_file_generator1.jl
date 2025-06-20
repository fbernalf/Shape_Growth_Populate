using Colors
using DataStructures # Pour utiliser Set

function generate_cell_type_xml(type_id, directions)
    color = RGB(rand(), rand(), rand())
    xml_line = "<cellType type=\"$(type_id)\" "
    xml_line *= "color0=\"$(red(color))\" color1=\"$(green(color))\" color2=\"$(blue(color))\" "
    xml_line *= "max_cell_division=\"6\" "
    for i in 0:length(directions)-1
        xml_line *= "dir$(i)=\"$(directions[i+1])\" "
    end
    xml_line *= "/>\n"
    return xml_line
end
function generate_unique_constrained_directions(possible_directions, num_elements, type_sequence)
    all_xml_lines = []
    seen_directions = Set{Vector{Int}}() # Ensemble pour stocker les séquences uniques
    indices_iterator = Iterators.product(fill(1:length(possible_directions), num_elements)...)
    num_types = length(type_sequence)
    type_index = 1

    for idx_tuple in indices_iterator
        directions = collect(possible_directions[i] for i in idx_tuple)
        constrained_directions = copy(directions)

        # Appliquer la contrainte: zéros APRÈS la première occurrence de 0 ou 1
        first_zero_one_index = findfirst(x -> x == 0 || x == 1, directions)
        if first_zero_one_index !== nothing
            for i in (first_zero_one_index + 1):num_elements
                constrained_directions[i] = 1
            end
        end

        # Vérifier si toutes les directions non-zéro sont distinctes
        non_zero_elements = filter(x -> x != 1, constrained_directions)
        if length(unique(non_zero_elements)) == length(non_zero_elements)
            # Vérifier si cette séquence contrainte a déjà été vue
            if !(constrained_directions in seen_directions)
                push!(seen_directions, constrained_directions)
                current_type_id = type_sequence[(type_index - 1) % num_types + 1]
                xml_line = generate_cell_type_xml(current_type_id, constrained_directions)
                push!(all_xml_lines, xml_line)
                type_index += 1
            end
        end
    end

    return all_xml_lines
end

function write_xml_to_file(filename, xml_lines)
    open(filename, "w") do io
        
        write(io, "<gene>\n")
        write(io, "<genome>\n")
        for line in xml_lines
            write(io, line)
        end
        write(io, "</genome>\n")
        write(io, "</gene>\n")
    end
    println("Les combinaisons de directions uniques et contraintes ont été écrites dans le fichier : $(filename)")
end

# Définir les directions possibles et le nombre d'éléments
possible_directions = 0:5
num_elements = 6 # Pour dir0 à dir5
type_sequence_to_iterate = 1:134 # Exemple de séquence de types

# Générer les combinaisons de directions uniques et contraintes
all_unique_constrained_xml = generate_unique_constrained_directions(possible_directions, num_elements, type_sequence_to_iterate)

# Écrire les combinaisons dans un nouveau fichier XML
output_filename = "essai_dir0_is_0_1_or_2.xml"
write_xml_to_file(output_filename, all_unique_constrained_xml)

println("Nombre total de combinaisons uniques et contraintes générées : $(length(all_unique_constrained_xml))")