defmodule ElixirConf2024Web.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use ElixirConf2024Web, :controller` and
  `use ElixirConf2024Web, :live_view`.
  """
  use ElixirConf2024Web, :html

  embed_templates "layouts/*"
end
