defmodule ChangelogWeb.Admin.EpisodeView do
  use ChangelogWeb, :admin_view

  alias Changelog.{Episode, EpisodeStat, Person, Sponsor, Topic}
  alias ChangelogWeb.{EpisodeView, PersonView, TimeView}
  alias ChangelogWeb.Admin.{EpisodeRequestView, PodcastView}

  def audio_filename(episode), do: EpisodeView.audio_filename(episode)
  def audio_url(episode), do: EpisodeView.audio_url(episode)
  def embed_code(episode), do: EpisodeView.embed_code(episode)
  def embed_iframe(episode, theme), do: EpisodeView.embed_iframe(episode, theme)
  def megabytes(episode), do: EpisodeView.megabytes(episode)
  def numbered_title(episode), do: EpisodeView.numbered_title(episode)

  def featured_label(episode) do
    if episode.featured do
      content_tag :span, "Recommended", class: "ui tiny blue basic label"
    end
  end

  def last_stat_date(podcast) do
    case PodcastView.last_stat(podcast) do
      stat = %{} ->
        {:ok, result} = Timex.format(stat.date, "{Mshort} {D}")
        result
      nil -> ""
    end
  end

  def performance_data(stats) when is_list(stats) do
    data = %{
      title: "Episode Performance",
      series: [
        %{name: "Launch",
          data: Enum.map(stats, fn({slug, reach, title, _reach}) ->
            %{x: slug, y: reach, title: title}
          end)},
        %{name: "Total",
          data: Enum.map(stats, fn({slug, _reach, title, reach}) ->
            %{x: slug, y: reach, title: title}
          end)}
      ]
    }

    Jason.encode!(data)
  end

  def line_chart_data(stats) when is_list(stats) do
    stats = Enum.reverse(stats)

    data = case length(stats) do
      l when l <= 45  -> get_chart_data(stats)
      l when l <= 365 -> get_chart_data_grouped_by(:week, stats)
      l when l <= 730 -> get_chart_data_grouped_by(:month, stats)
      _else -> get_chart_data_grouped_by(:year, stats)
    end

    Jason.encode!(data)
  end

  defp get_chart_data_grouped_by(interval, stats) do
    {title, grouper} = case interval do
      :week -> {"Week Chart", &Timex.beginning_of_week/1}
      :month -> {"Month Chart", &Timex.beginning_of_month/1}
      :year -> {"Year Chart", &Timex.beginning_of_year/1}
    end

    stats
    |> Enum.map(fn(stat) -> Map.put(stat, :date, grouper.(stat.date)) end)
    |> Enum.group_by(&(&1.date))
    |> Enum.map(fn({date, list}) ->
      %{
        date: date,
        downloads: list |> Enum.map(&(&1.downloads)) |> Enum.sum(),
        uniques: list |> Enum.map(&(&1.uniques)) |> Enum.sum()
      }
    end)
    |> Enum.sort(&(Timex.before?(&1.date, &2.date)))
    |> get_chart_data(title)
  end

  defp get_chart_data(stats, title \\ "Day Chart") do
    %{
      title: title,
      categories: Enum.map(stats, &stat_chart_date/1),
      series: [
        %{name: "Reach", data: Enum.map(stats, &(&1.uniques))},
        %{name: "Downloads", data: Enum.map(stats, &(Float.round(&1.downloads)))}
      ]
    }
  end

  defp stat_chart_date(stat) do
    {:ok, date} = Timex.format(stat.date, "{M}/{D}/{YYYY}")
    date
  end

  def request_options(requests) do
    Enum.map(requests, fn(request) ->
      {EpisodeRequestView.description(request), request.id}
    end)
  end

  def round_and_filter(stats) do
    stats
    |> Enum.map(fn({key, value}) -> {key, round(value)} end)
    |> Enum.reject(fn({_key, value}) -> value == 0 end)
  end

  def status_label(episode) do
    if episode.published do
      content_tag :span, "Published", class: "ui tiny green basic label"
    else
      content_tag :span, "Draft", class: "ui tiny yellow basic label"
    end
  end

  def show_or_preview(episode) do
    if Episode.is_public(episode) do
      :show
    else
      :preview
    end
  end

  def stat_date(nil), do: "never"
  def stat_date(stat) do
    {:ok, result} = Timex.format(stat.date, "{WDshort}, {M}/{D}")
    result
  end

  def type_options do
    Episode.Type.__enum_map__()
    |> Enum.map(fn({k, _v}) -> {String.capitalize(Atom.to_string(k)), k} end)
  end
end
