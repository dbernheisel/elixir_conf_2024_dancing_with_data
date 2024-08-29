defmodule Business do
  @type t :: nil
  def create(_, _), do: {:ok, nil}
end

defmodule User do
  @type t :: nil
  defstruct []
end

defmodule ElixirConf2024.With do
  alias ElixirConf2024.Simple
  require Logger, warn: false

  @defaults [
    yell: "outside",
    whisper_yell: "restained",
    shh: "strange low"
  ]




  @doc """
  Exercise all the voices. This is great. We're composing functions.
  However, we're bubbling up invisible errors. Since they can all have
  the same ambiguous `:error` return, we don't know which one failed.
  """
  def compose(what, opts \\ []) do
    {:ok, opts} = Keyword.validate(opts, @defaults)

    with {:ok, yelled} <- Simple.yell(opts[:yell]),
         {:ok, restrained} <- Simple.whisper_yell(opts[:whisper_yell]),
         {:ok, shushed} <- Simple.shh(opts[:shh]) do
      {:ok,
       Enum.join([
         "I have a ",
         Enum.join([yelled, restrained, shushed], " and "),
         " ",
         what
       ])}
    end
  end




  @doc """
  But you might be tempted to tag your composed functions in the `with`
  """
  def poorly_compose(what, opts \\ []) do
    {:ok, opts} = Keyword.validate(opts, @defaults)

    with {:yell, {:ok, yelled}} <- {:yell, Simple.yell(opts[:yell])},
         {:whisper_yell, {:ok, restrained}} <-
           {:whisper_yell, Simple.whisper_yell(opts[:whisper_yell])},
         {:shushed, {:ok, shushed}} <- {:shushed, Simple.shh(opts[:shh])} do
      {:ok,
       Enum.join([
         "I have a ",
         Enum.join([yelled, restrained, shushed], " and "),
         " ",
         what
       ])}
    end
  end


  @doc """
  Good composing with common function signatures, such as two
  Ecto Repo insert functions. The changeset will reveal the
  sensible line that threw the error
  """
  @spec context(map, User.t, Keyword.t()) ::
    {:ok, Business.t()} | {:error, Ecto.Changeset.t()}
  def context(attrs, %User{} = user, opts \\ []) do
    {:ok, opts} = Keyword.validate(opts, @defaults)
    attrs = Map.put(attrs, :user, user)

    with {:ok, biznass} <- Business.create(attrs, opts),
      {:ok, _audit} <- insert_audit_log(biznass, user) do
      {:ok, biznass}
    end
  end







  defp insert_audit_log(_, _), do: {:ok, nil}
end

# set noshowmode
# set noruler
# set laststatus=0
# set noshowcmd
# set nonumber
# set foldcolumn=9
# hi Comment guifg=#ffffff gui=bold


