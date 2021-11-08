defmodule GenReport do
  alias GenReport.Parser

  @report_acc %{
    "all_hours" => %{},
    "hours_per_month" => %{},
    "hours_per_year" => %{}
  }

  # construir vários
  def build(filenames) do
    filenames
    |> Task.async_stream(&build_one/1)
    |> Enum.reduce(@report_acc, fn {:ok, result}, report_acc ->
      sum_reports(result, report_acc)
    end)
  end

  def build() do
    {:error, "Insira a lista dos arquivos"}
  end

  # construir um relatório
  def build_one(filename) do
    list =
      filename
      |> Parser.parse_file()

    Enum.reduce(list, initialize_report_acc(list), fn line, report_acc ->
      sum_values(line, report_acc)
    end)
  end

  # somar valores e atualizar o map
  defp sum_reports(
         %{
           "all_hours" => people_hours1,
           "hours_per_month" => people_month1,
           "hours_per_year" => people_year1
         },
         %{
           "all_hours" => people_hours2,
           "hours_per_month" => people_month2,
           "hours_per_year" => people_year2
         }
       ) do
    build_report(
      merge_maps(people_hours1, people_hours2),
      merge_maps_with_map(people_month1, people_month2),
      merge_maps_with_map(people_year1, people_year2)
    )
  end

  defp merge_maps_with_map(map1, map2) do
    Map.merge(map1, map2, fn _key, other_map1, other_map2 ->
      merge_maps(other_map1, other_map2)
    end)
  end

  defp merge_maps(map1, map2) do
    Map.merge(map1, map2, fn _key, value1, value2 -> value1 + value2 end)
  end

  defp sum_values([name, hours, _day, month, year], %{
         "all_hours" => people_hours,
         "hours_per_month" => people_month,
         "hours_per_year" => people_year
       }) do
    build_report(
      sum_people_hours(people_hours, name, hours),
      sum_people_month(people_month, name, hours, month),
      sum_people_year(people_year, name, hours, year)
    )
  end

  defp sum_people_hours(people_hours, name, hours) do
    Map.put(people_hours, name, people_hours[name] + hours)
  end

  defp sum_people_month(people_month, name, hours, month) do
    Map.put(people_month, name, update_value(people_month[name], month, hours))
  end

  defp sum_people_year(people_year, name, hours, year) do
    Map.put(people_year, name, update_value(people_year[name], year, hours))
  end

  defp update_value(map, key, value) do
    Map.put(map, key, map[key] + value)
  end

  # inicializar acumulador antes de construir relatório
  defp initialize_list_name(list, value) do
    Enum.into(list, %{}, fn [name, _, _, _, _] -> {name, value} end)
  end

  defp initialize_report_acc(list) do
    build_report(
      initialize_report_acc(list, "hours"),
      initialize_report_acc(list, "months"),
      initialize_report_acc(list, "years")
    )
  end

  defp initialize_report_acc(list, "hours" = _option) do
    initialize_list_name(list, 0)
  end

  defp initialize_report_acc(list, "months" = _option) do
    months = Enum.into(list, %{}, fn [_, _, _, month, _] -> {month, 0} end)
    initialize_list_name(list, months)
  end

  defp initialize_report_acc(list, "years" = _option) do
    years = Enum.into(list, %{}, fn [_, _, _, _, year] -> {year, 0} end)
    initialize_list_name(list, years)
  end

  # construir relatório
  defp build_report(people_hours, people_month, people_year) do
    %{
      "all_hours" => people_hours,
      "hours_per_month" => people_month,
      "hours_per_year" => people_year
    }
  end
end
