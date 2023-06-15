#!/bin/bash

# Проверяем, что передано корректное количество аргументов
if [ $# -ne 2 ]; then
    echo "Usage: $0 source_hats_path dest_path"
    exit 1
fi

CP() {
    mkdir -p $(dirname "$2") && cp "$1" "$2"
}

# Получаем абсолютный путь к указанной директории
dir=$(realpath "$1")
dest=$(realpath "$2")

dest_prj_name=$(echo "$2" | tr -d '/')

#Обновляем список предметов и язик
CP "items_start.yml" "$dest/configs/items.yml"
# CP "en_start.yml" "$dest/configs/_dictionaries/en.yml"
CP "categories_start.yml" "$dest/configs/categories.yml"

sed -i "s/put_here/$2/g" "$dest/configs/categories.yml"
sed -i "s/put_here/$2/g" "$dest/configs/items.yml"
sed -i "s/put_here/$2/g" "$dest/configs/_dictionaries/en.yml"

rm -rf "$dest/resourcepack/$2/models"
rm -rf "$dest/resourcepack/$2/textures"

# Читаем шаблон шляпы
template=$(cat hat_template.yml)
# Перебираем все папки в указанной директории
for subdir in "${dir}"/*
do
  for file in "${subdir}"/*.properties
  do
    # Проверяем, что это действительно файл с расширением ".properties"
    if [ -f "$file" ]
    then
      # Берём данные о модели
      #matchItems=$(grep "matchItems=" "$base_file" | cut -d "=" -f 2)
      model=$(grep "model=" "$file" | cut -d "=" -f 2 | tr -d '\r')

      if [[ "$model" == *.json ]]; then
        model="${model%.*}"
        #model=$(echo "$model" | tr -d '.json')
      fi

      name=$(grep "nbt.display.Name=" "$file" | cut -d "=" -f 2 | sed 's/.*|\(.*\)).*/\1/')
      model_file="$model".json
      # Меняем значения текстур и помещаем изменённый файл на наш склад готовых моделей
      CP "$subdir/$model_file" "$dest/resourcepack/$dest_prj_name/models/$model_file"
      sed -i "s/\.\//\ mttffr:\//g" "$dest/resourcepack/$dest_prj_name/models/$model_file"
      # Убираем лишний пробел
      sed -i "s/ mttffr:/mttffr:/g" "$dest/resourcepack/$dest_prj_name/models/$model_file"
      # Убираем слеши
      sed -i 's/\///g' "$dest/resourcepack/$dest_prj_name/models/$model_file"
      # Возьмём данные о текстурах
      #zerotexture=$(grep '"0":' "$dest/resourcepack/$dest_prj_name/models/$model_file" | cut -d ":" -f 2 | tr -d '",' | tr -d '\r' | tr -d ' ')
      #  step_=$()
      step_one=$(grep '"0":' "$dest/resourcepack/$dest_prj_name/models/$model_file")
      step_two=$(echo "$step_one" | cut -d ":" -f 3)
      step_three=$(echo "$step_two" | tr -d '",')
      step_four=$(echo "$step_three" | tr -d '\r')
      final=$(echo "$step_four" | tr -d ' ')
      zerotexture="$final"
      # Также копируем текстуры
      CP "$subdir/$zerotexture.png" "$dest/resourcepack/$dest_prj_name/textures/$zerotexture.png"
      # Добавляем запись в файл конфигурации
      hat_file="${template//<hat_name>/"$model"}"
      hat_file="${hat_file//<root>/"$dest_prj_name"}"
      # Перевод названия
      name=$(trans -b en:ru "$name")
      # Вставляем переведённое название
      hat_file="${hat_file//<full_hat_name>/"$name"}"
      
      echo "$hat_file" >> "$dest/configs/items.yml"

      printf "      - %s:%s\n" "$dest_prj_name" "$model" >> "$dest/configs/categories.yml"
    fi
  done
done