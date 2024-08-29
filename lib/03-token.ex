defmodule ElixirConf2024.Token do
  alias ElixirConf2024.Simple
  alias __MODULE__, as: Token

  # This usage example is responsible for composing the Token struct
  # and deciding when to emit the side effect. It's not responsible for
  # anything other than orchestration.
  def example do
    Token.new()
    |> Token.yell("YOOO")
    |> Token.whisper_yell("excited")
    |> Token.shush("numeric")
    |> Token.print!("voices")
  end










  @defaults [
    yell: "outside",
    whisper_yell: "restained",
    shh: "strange low"
  ]

  # Define our Token struct and builder function
  defstruct [:yelled, :restrained, :shushed, errors: []]

  def new(state \\ %Token{}), do: state










  # For each action, we'll handle those disparate functions appropriately
  # including error handling
  def yell(state, str \\ nil) do
    case Simple.yell(str || @defaults[:yell]) do
      {:ok, yelled} -> %{state | yelled: yelled}
      error -> handle_error(state, :yelled, error)
    end
  end

  def whisper_yell(state, str \\ nil) do
    case Simple.whisper_yell(str || @defaults[:whisper_yell]) do
      {:ok, restrained} -> %{state | restrained: restrained}
      error -> handle_error(state, :restrained, error)
    end
  end

  def shush(state, str \\ nil) do
    case Simple.shh(str || @defaults[:shh]) do
      {:ok, shushed} -> %{state | shushed: shushed}
      error -> handle_error(state, :shushed, error)
    end
  end










  # We can still abstract and compose with private functions
  # as usual
  defp handle_error(%Token{} = state, key, {:error, error}) do
    %{state | errors: [{key, error} | state.errors]}
  end

  defp handle_error(%Token{} = state, key, :error) do
    %{state | errors: [{key, :error} | state.errors]}
  end

  def validate(%Token{errors: []} = state), do: {:ok, state}
  def validate(%Token{errors: _errors} = state), do: {:error, state}










  # Then we can have functions that focus on the side-effects emitted
  # with the given state
  defmodule PrintError do
    defexception [:message, :state]
  end

  def print!(%Token{} = state, what) do
    case validate(state) do
      {:ok, state} ->
        Enum.join([
          "I have a ",
          Enum.join([state.yelled, state.restrained, state.shushed], " and "),
          " ",
          what
        ])

      {:error, state} ->
        raise PrintError, message: "Invalid state: #{inspect(state.errors)}", state: state
    end
  end
end
