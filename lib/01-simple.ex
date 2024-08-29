defmodule ElixirConf2024.Simple do
  @moduledoc "Talking Simple"

  @smallcaps Enum.zip(
    ~w[A B C D E F G H I J K L M N O P Q R S T U V X Y Z],
    ~w[ᴀ ʙ ᴄ ᴅ ᴇ ғ ɢ ʜ ɪ ᴊ ᴋ ʟ ᴍ ɴ ᴏ ᴘ ǫ ʀ s ᴛ ᴜ ᴠ x ʏ ᴢ]
  )

  @subs Enum.zip(
    ~w[0 1 2 3 4 5 6 7 8 9 + - = ( ) e h i j k l m n o p r s t u v x] ++
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    ~w[₀ ₁ ₂ ₃ ₄ ₅ ₆ ₇ ₈ ₉ ₊ ₋ ₌ ₍ ₎ ₑ ₕ ᵢ ⱼ ₖ ₗ ₘ ₙ ₒ ₚ ᵣ ₛ ₜ ᵤ ᵥ ₓ] ++
    ~w[₀ ₁ ₂ ₃ ₄ ₅ ₆ ₇ ₈ ₉]
  )




  @doc """
  Yells a string.
  This is a good function. As simple as it can get
  """
  @spec yell(String.t()) :: {:ok, String.t()} | :error
  def yell(str) when is_binary(str) do
    {:ok,
     str
     |> String.split(" ")
     |> Enum.map(&String.upcase/1)
     |> Enum.join(" ")}
  end

  def yell(_), do: :error






  @doc """
  Whisper-yells a string. This is good, starting to compose with
  private functions to encapsulate recursion and/or name portions
  """
  @spec whisper_yell(String.t()) :: {:ok, String.t()} | :error
  def whisper_yell(str) when is_binary(str) do
    {:ok,
     str
     |> String.split("")
     |> Enum.map(&do_whisper_yell/1)
     |> Enum.join("")}
  end

  def whisper_yell(_), do: :error

  for {upper, smallcap} <- @smallcaps do
    defp do_whisper_yell(unquote(upper)), do: unquote(smallcap)
    defp do_whisper_yell(unquote(String.downcase(upper))), do: unquote(smallcap)
  end
  defp do_whisper_yell(c) when is_binary(c), do: String.downcase(c)





  @doc """
  Shushes a string. This is still good,
  but now we're dealing with more types which branches more.
  """
  @spec shh(String.t() | integer) :: {:ok, String.t()} | :error
  def shh(str) when is_binary(str) do
    {:ok, str |> String.split("") |> Enum.map(&do_shh/1) |> Enum.join("")}
  end

  def shh(int) when is_integer(int) do
    {:ok, int |> Integer.digits() |> Enum.map(&do_shh/1) |> Enum.join("")}
  end

  def shh(_), do: :error

  for {base, sub} <- @subs do
    defp do_shh(unquote(base)), do: unquote(sub)
  end
  defp do_shh(c) when is_binary(c), do: String.downcase(c)
  defp do_shh(c) when is_number(c), do: c



  @doc """
  Is the string yelling?
  Now we're venturing into weird territory. If I want to chain
  together `str |> yell() |> yelling?()` I now need to have
  knowledge of the shape of earlier output to make it ergonomic.
  """
  @spec yelling?(String.t()) :: boolean
  def yelling?(str) when is_binary(str) do
    str |> String.split("") |> Enum.all?(&String.upcase(&1) == &1)
  end

  # I am disappoint
  def yelling?({:ok, str}), do: yelling?(str)
  def yelling?(:error), do: :error










  # I am disgusted. Please, for the love of God, no! Go to your room
  # and think about what you've done
  def quiet?(str), do: str |> yelling?() |> Kernel.not()
  def talking?(str), do: str |> yelling?() |> Kernel.||(quiet?(str))










end
# set noshowmode
# set noruler
# set laststatus=0
# set noshowcmd
# set nonumber
# set foldcolumn=9
# hi Comment guifg=#ffffff gui=bold
