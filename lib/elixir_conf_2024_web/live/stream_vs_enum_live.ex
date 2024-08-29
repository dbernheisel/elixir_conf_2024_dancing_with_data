defmodule ElixirConf2024Web.StreamVsEnumLive do
  use ElixirConf2024Web, :live_view
  @items ~w[foo bar baz qux quux corge grault garply waldo fred plugh xyzzy thud]
  @sleep 200
  @flow false

  defstruct [:id, :value, working: false, active: false, phase: 0]

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      me = self()

      Task.async(fn ->
        send(me, {:baseline, :erlang.process_info(self(), [:memory])[:memory]})
      end)
    end

    {:ok,
     socket
     |> assign(:flow_enabled, @flow)
     |> stream_configure(:enum_items, dom_id: &"enum-#{&1.id}")
     |> stream_configure(:stream_items, dom_id: &"stream-#{&1.id}")
     |> stream_configure(:flow_items, dom_id: &"flow-#{&1.id}")
     |> reset()}
  end

  defp reset(socket) do
    if enum = socket.assigns[:enum], do: Task.shutdown(enum)
    if stream = socket.assigns[:stream], do: Task.shutdown(stream)
    if flow = socket.assigns[:flow], do: Task.shutdown(flow)

    socket
    |> assign(
      enum: nil,
      enum_done: false,
      enum_mem: nil,
      enum_red: nil,
      stream: nil,
      stream_done: false,
      stream_mem: nil,
      stream_red: nil,
      flow: nil,
      flow_done: 999_999_999_999,
      flow_mem: nil,
      flow_red: nil
    )
    |> stream(
      :enum_items,
      Enum.map(@items, fn i -> %__MODULE__{id: i, value: i} end),
      reset: true
    )
    |> stream(
      :stream_items,
      Enum.map(@items, fn i -> %__MODULE__{id: i, value: i} end),
      reset: true
    )
    |> stream(
      :flow_items,
      Enum.map(@items, fn i -> %__MODULE__{id: i, value: i} end),
      reset: true
    )
  end

  @impl true
  def handle_event("start", _params, socket) do
    {:noreply, socket |> reset() |> start_flow() |> start_stream |> start_enum()}
  end

  def handle_event("stop", _params, socket) do
    {:noreply, reset(socket)}
  end

  @impl true

  def handle_info({:baseline, mem}, socket) do
    {:noreply, assign(socket, baseline_mem: mem)}
  end

  def handle_info({:enum, {id, phase, value, status}}, socket) do
    {:noreply,
     stream_insert(socket, :enum_items, %__MODULE__{
       id: id,
       working: status == :start,
       phase: phase,
       value: value
     })}
  end

  def handle_info({:stream, {id, phase, value, status}}, socket) do
    {:noreply,
     stream_insert(socket, :stream_items, %__MODULE__{
       id: id,
       working: status == :start,
       phase: phase,
       value: value
     })}
  end

  def handle_info({:flow, {id, phase, value, status}}, socket) do
    {:noreply,
     stream_insert(socket, :flow_items, %__MODULE__{
       id: id,
       working: status == :start,
       phase: phase,
       value: value
     })}
  end

  def handle_info({:enum, :info, info}, socket) do
    {:noreply,
     assign(socket,
       enum_mem: info[:memory] - socket.assigns.baseline_mem,
       enum_red: info[:reductions]
     )}
  end

  def handle_info({:stream, :info, info}, socket) do
    {:noreply,
     assign(socket,
       stream_mem: info[:memory] - socket.assigns.baseline_mem,
       stream_red: info[:reductions]
     )}
  end

  def handle_info({:flow, :info, info}, socket) do
    {:noreply,
     assign(socket,
       flow_mem: info[:memory] - socket.assigns.baseline_mem,
       flow_red: info[:reductions]
     )}
  end

  def handle_info({:DOWN, ref, _, _, _}, socket) do
    {:noreply,
     case socket.assigns do
       %{enum: %{ref: ^ref}} -> assign(socket, :enum, nil)
       %{stream: %{ref: ^ref}} -> assign(socket, :stream, nil)
       %{flow: %{ref: ^ref}} -> assign(socket, :flow, nil)
       _ -> socket
     end}
  end

  def handle_info({ref, {time, _result}}, socket) do
    {:noreply,
     case socket.assigns do
       %{enum: %{ref: ^ref}} -> assign(socket, :enum_done, time)
       %{stream: %{ref: ^ref}} -> assign(socket, :stream_done, time)
       %{flow: %{ref: ^ref}} -> assign(socket, :flow_done, time)
       _ -> socket
     end}
  end

  def work_enum(who) do
    results =
      @items
      |> Enum.map(fn i ->
        send(who, {:enum, {i, 1, i, :start}})
        if @sleep, do: Process.sleep(@sleep)
        new = String.capitalize(i)
        send(who, {:enum, {i, 1, new, :end}})
        {i, new}
      end)
      |> Enum.map(fn {i, o} ->
        send(who, {:enum, {i, 2, o, :start}})
        if @sleep, do: Process.sleep(@sleep)
        new = String.upcase(o)
        send(who, {:enum, {i, 2, new, :end}})
        {i, new}
      end)
      |> Enum.map(fn {i, o} ->
        send(who, {:enum, {i, 3, o, :start}})
        if @sleep, do: Process.sleep(@sleep)
        new = String.downcase(i)
        send(who, {:enum, {i, 3, new, :end}})
        new
      end)

    send(who, {:enum, :info, :erlang.process_info(self(), [:reductions, :memory])})

    results
  end

  def work_stream(who) do
    values =
      @items
      |> Stream.map(fn i ->
        send(who, {:stream, {i, 1, i, :start}})
        if @sleep, do: Process.sleep(@sleep)
        new = String.capitalize(i)
        send(who, {:stream, {i, 1, new, :end}})
        {i, new}
      end)
      |> Stream.map(fn {i, o} ->
        send(who, {:stream, {i, 2, o, :start}})
        if @sleep, do: Process.sleep(@sleep)
        new = String.upcase(o)
        send(who, {:stream, {i, 2, new, :end}})
        {i, new}
      end)
      |> Stream.map(fn {i, o} ->
        send(who, {:stream, {i, 3, o, :start}})
        if @sleep, do: Process.sleep(@sleep)
        new = String.downcase(i)
        send(who, {:stream, {i, 3, new, :end}})
        new
      end)
      |> Stream.run()

    send(who, {:stream, :info, :erlang.process_info(self(), [:reductions, :memory])})
    values
  end

  def work_flow(who) do
    values =
      @items
      |> Flow.from_enumerable()
      |> Flow.partition(stages: 3)
      |> Flow.map(fn i ->
        send(who, {:flow, {i, 1, i, :start}})
        if @sleep, do: Process.sleep(@sleep)
        new = String.capitalize(i)
        send(who, {:flow, {i, 1, new, :end}})
        {i, new}
      end)
      |> Flow.map(fn {i, o} ->
        send(who, {:flow, {i, 2, o, :start}})
        if @sleep, do: Process.sleep(@sleep)
        new = String.upcase(o)
        send(who, {:flow, {i, 2, new, :end}})
        {i, new}
      end)
      |> Flow.map(fn {i, o} ->
        send(who, {:flow, {i, 3, o, :start}})
        if @sleep, do: Process.sleep(@sleep)
        new = String.downcase(i)
        send(who, {:flow, {i, 3, new, :end}})
        new
      end)
      |> Flow.run()

    send(who, {:flow, :info, :erlang.process_info(self(), [:reductions, :memory])})
    values
  end

  def start_flow(socket) do
    if socket.assigns.flow_enabled do
      me = self()

      assign(
        socket,
        :flow,
        Task.async(fn ->
          :timer.tc(__MODULE__, :work_flow, [me], :nanosecond)
        end)
      )
    else
      socket
    end
  end

  def start_enum(socket) do
    me = self()

    assign(
      socket,
      :enum,
      Task.async(fn ->
        :timer.tc(__MODULE__, :work_enum, [me], :nanosecond)
      end)
    )
  end

  def start_stream(socket) do
    me = self()

    assign(
      socket,
      :stream,
      Task.async(fn ->
        :timer.tc(__MODULE__, :work_stream, [me], :nanosecond)
      end)
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mb-12 w-full flex justify-around">
      <button
        phx-click="start"
        disabled={not is_nil(@enum) and not is_nil(@stream)}
        type="button"
        class="rounded-md bg-green-600 px-3.5 py-2.5 text-sm font-semibold w-60
        inline-flex items-center justify-center gap-x-1.5
        disabled:bg-gray-600 disabled:text-gray-200
        text-white shadow-sm hover:bg-green-500
        focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-green-600"
      >
        Start <.icon name="hero-clock-solid" class="h-4 w-4" />
      </button>

      <button
        phx-click="stop"
        disabled={is_nil(@enum) or is_nil(@stream)}
        type="button"
        class="rounded-md bg-red-600 px-3.5 py-2.5 text-sm font-semibold w-60
        inline-flex items-center justify-center gap-x-1.5
        disabled:bg-gray-600 disabled:text-gray-200
        text-white shadow-sm hover:bg-red-500
        focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"
      >
        Stop <.icon name="hero-x-circle-solid" class="h-5 w-5" />
      </button>
    </div>

    <div class={[(@flow_enabled && "columns-3") || "columns-2", "divide-x divide-white/5"]}>
      <div>
        <div class="w-full text-center font-2xl font-bold">
          <div class="min-h-28 flex gap-x-3 items-center justify-center">
            ENUM
            <div :if={
              @stream_done && @enum_done && @flow_done &&
              @stream_done > @enum_done && @flow_done > @enum_done}>
              <.icon class="text-green-500 h-5 w-5" name="hero-flag" />
              <span class="ml-2 text-green-500">
                -<%= Integer.digits(min(@stream_done, @flow_done) - @enum_done)
                |> Enum.reverse()
                |> Enum.chunk_every(3)
                |> Enum.map(&Enum.join(Enum.reverse(&1), ""))
                |> Enum.reverse()
                |> Enum.join(",") %>ns
              </span>
            </div>
          </div>
          <div :if={@enum_done}>
            <div>
              <span class="font-normal text-gray-700">Time (tc): </span>
              <%= Integer.digits(@enum_done)
              |> Enum.reverse()
              |> Enum.chunk_every(3)
              |> Enum.map(&Enum.join(Enum.reverse(&1), ""))
              |> Enum.reverse()
              |> Enum.join(",") %>ns
            </div>
            <div><span class="font-normal text-gray-700">Memory: </span><%= @enum_mem %> bytes</div>
            <div><span class="font-normal text-gray-700">Reductions: </span><%= @enum_red %></div>
          </div>
        </div>

        <div class="m-4 overflow-hidden bg-white">
          <ul id="enum-stream" phx-update="stream" role="list" class="divide-y divide-white/5">
            <li
              :for={{dom_id, item} <- @streams.enum_items}
              id={dom_id}
              class={[
                "px-6 py-4 rounded-lg",
                "transition-colors duration-500 ease-[cubic-bezier(0,1,0.75,1)]",
                item.working && "bg-green-200"
              ]}
            >
              <div class="w-full bg-gray-200 rounded-full h-2.5">
                <div
                  data-width={round(item.phase / 3 * 100)}
                  class={[
                    "h-2.5 rounded-full",
                    "data-[width='0']:scale-x-0",
                    "data-[width='0']:bg-gray-600",
                    "data-[width='33']:scale-x-[33%]",
                    "data-[width='33']:bg-red-600",
                    "data-[width='67']:scale-x-[67%]",
                    "data-[width='67']:bg-yellow-600",
                    "data-[width='100']:scale-x-100",
                    "data-[width='100']:bg-green-600",
                    "transition origin-left"
                  ]}
                >
                </div>
              </div>
              <div class="min-w-0 flex-auto">
                <div class="flex items-center gap-x-3">
                  <div class={[
                    "flex-none rounded-full",
                    !item.working && "bg-red-100/10 p-1 text-red-500",
                    item.working && "bg-green-100/10 p-1 text-green-500"
                  ]}>
                    <div class="h-2 w-2 rounded-full bg-current"></div>
                  </div>
                  <h2 class="min-w-0 text-sm font-semibold leading-6 text-black">
                    <div class="flex gap-x-2">
                      Phase <%= item.phase %> - <span class="font-mono"><%= item.value %></span>
                    </div>
                  </h2>
                </div>
              </div>
            </li>
          </ul>
        </div>
      </div>

      <div>
        <div class="w-full text-center font-2xl font-bold">
          <div class="flex min-h-28 gap-x-3 items-center justify-center">
            STREAM
            <div :if={
              @stream_done && @enum_done && @flow_done &&
              @enum_done > @stream_done && @flow_done > @stream_done}>
              <.icon class="text-green-500 h-5 w-5" name="hero-flag" />
              <span class="ml-2 text-green-500">
                -<%= Integer.digits(min(@flow_done, @enum_done) - @stream_done)
                |> Enum.reverse()
                |> Enum.chunk_every(3)
                |> Enum.map(&Enum.join(Enum.reverse(&1), ""))
                |> Enum.reverse()
                |> Enum.join(",") %>ns
              </span>
            </div>
          </div>
          <div :if={@stream_done}>
            <div>
              <span class="font-normal text-gray-700">Time (tc): </span>
              <%= Integer.digits(@stream_done)
              |> Enum.reverse()
              |> Enum.chunk_every(3)
              |> Enum.map(&Enum.join(Enum.reverse(&1), ""))
              |> Enum.reverse()
              |> Enum.join(",") %>ns
            </div>
            <div><span class="font-normal text-gray-700">Memory: </span><%= @stream_mem %> bytes</div>
            <div><span class="font-normal text-gray-700">Reductions: </span><%= @stream_red %></div>
          </div>
        </div>

        <div class="m-4 overflow-hidden bg-white">
          <ul id="stream-stream" phx-update="stream" role="list" class="divide-y divide-white/5">
            <li
              :for={{dom_id, item} <- @streams.stream_items}
              id={dom_id}
              class={[
                "px-6 py-4 rounded-lg",
                "transition-colors duration-500 ease-[cubic-bezier(0,1,0.75,1)]",
                item.working && "bg-green-200"
              ]}
            >
              <div class="w-full bg-gray-200 rounded-full h-2.5">
                <div
                  data-width={round(item.phase / 3 * 100)}
                  class={[
                    "h-2.5 rounded-full",
                    "data-[width='0']:scale-x-0",
                    "data-[width='0']:bg-gray-600",
                    "data-[width='33']:scale-x-[33%]",
                    "data-[width='33']:bg-red-600",
                    "data-[width='67']:scale-x-[67%]",
                    "data-[width='67']:bg-yellow-600",
                    "data-[width='100']:scale-x-100",
                    "data-[width='100']:bg-green-600",
                    "transition origin-left"
                  ]}
                >
                </div>
              </div>
              <div class="min-w-0 flex-auto">
                <div class="flex items-center gap-x-3">
                  <div class={[
                    "flex-none rounded-full",
                    !item.working && "bg-red-100/10 p-1 text-red-500",
                    item.working && "bg-green-100/10 p-1 text-green-500"
                  ]}>
                    <div class="h-2 w-2 rounded-full bg-current"></div>
                  </div>
                  <h2 class="min-w-0 text-sm font-semibold leading-6 text-black">
                    <div class="flex gap-x-2">
                      Phase <%= item.phase %> - <span class="font-mono"><%= item.value %></span>
                    </div>
                  </h2>
                </div>
              </div>
            </li>
          </ul>
        </div>
      </div>

      <div :if={@flow_enabled}>
        <div class="w-full text-center font-2xl font-bold">
          <div class="flex min-h-28 gap-x-3 items-center justify-center">
            FLOW
            <div :if={
              @flow_done != 999_999_999_999 &&
              @stream_done && @enum_done && @flow_done &&
              @stream_done > @flow_done && @enum_done > @flow_done}>
              <.icon class="text-green-500 h-5 w-5" name="hero-flag" />
              <span class="ml-2 text-green-500">
                -<%= Integer.digits(min(@stream_done, @enum_done) - @flow_done)
                |> Enum.reverse()
                |> Enum.chunk_every(3)
                |> Enum.map(&Enum.join(Enum.reverse(&1), ""))
                |> Enum.reverse()
                |> Enum.join(",") %>ns
              </span>
            </div>
          </div>
          <div :if={@flow_done && @flow_done != 999_999_999_999}>
            <div>
              <span class="font-normal text-gray-700">Time (tc): </span>
              <%= Integer.digits(@flow_done)
              |> Enum.reverse()
              |> Enum.chunk_every(3)
              |> Enum.map(&Enum.join(Enum.reverse(&1), ""))
              |> Enum.reverse()
              |> Enum.join(",") %>ns
            </div>
            <div><span class="font-normal text-gray-700">Memory: </span><%= @flow_mem %> bytes</div>
            <div><span class="font-normal text-gray-700">Reductions: </span><%= @flow_red %></div>
          </div>
        </div>

        <div class="m-4 overflow-hidden bg-white">
          <ul id="flow-stream" phx-update="stream" role="list" class="divide-y divide-white/5">
            <li
              :for={{dom_id, item} <- @streams.flow_items}
              id={dom_id}
              class={[
                "px-6 py-4 rounded-lg",
                "transition-colors duration-500 ease-[cubic-bezier(0,1,0.75,1)]",
                item.working && "bg-green-200"
              ]}
            >
              <div class="w-full bg-gray-200 rounded-full h-2.5">
                <div
                  data-width={round(item.phase / 3 * 100)}
                  class={[
                    "h-2.5 rounded-full",
                    "data-[width='0']:scale-x-0",
                    "data-[width='0']:bg-gray-600",
                    "data-[width='33']:scale-x-[33%]",
                    "data-[width='33']:bg-red-600",
                    "data-[width='67']:scale-x-[67%]",
                    "data-[width='67']:bg-yellow-600",
                    "data-[width='100']:scale-x-100",
                    "data-[width='100']:bg-green-600",
                    "transition origin-left"
                  ]}
                >
                </div>
              </div>
              <div class="min-w-0 flex-auto">
                <div class="flex items-center gap-x-3">
                  <div class={[
                    "flex-none rounded-full",
                    !item.working && "bg-red-100/10 p-1 text-red-500",
                    item.working && "bg-green-100/10 p-1 text-green-500"
                  ]}>
                    <div class="h-2 w-2 rounded-full bg-current"></div>
                  </div>
                  <h2 class="min-w-0 text-sm font-semibold leading-6 text-black">
                    <div class="flex gap-x-2">
                      Phase <%= item.phase %> - <span class="font-mono"><%= item.value %></span>
                    </div>
                  </h2>
                </div>
              </div>
            </li>
          </ul>
        </div>
      </div>
    </div>
    """
  end
end
