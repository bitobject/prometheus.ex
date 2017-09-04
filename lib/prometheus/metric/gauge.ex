defmodule Prometheus.Metric.Gauge do
  @moduledoc """
  Gauge metric, to report instantaneous values.

  Gauge is a metric that represents a single numerical value that can
  arbitrarily go up and down.

  A Gauge is typically used for measured values like temperatures or current
  memory usage, but also "counts" that can go up and down, like the number of
  running processes.

  Example use cases for Gauges:
    - Inprogress requests;
    - Number of items in a queue;
    - Free memory;
    - Total memory;
    - Temperature.

  Example:

  ```
  defmodule MyPoolInstrumenter do

    use Prometheus.Metric

    ## to be called at app/supervisor startup.
    ## to tolerate restarts use declare.
    def setup() do
      Gauge.declare([name: :my_pool_size,
                     help: "Pool size."])

      Gauge.declare([name: :my_pool_checked_out,
                     help: "Number of sockets checked out from the pool"])
    end

    def set_size(size) do
      Gauge.set([name: :my_pool_size], size)
    end

    def track_checked_out_sockets(checkout_fun) do
      Gauge.track_inprogress([name: :my_pool_checked_out], checkout_fun)
    end

  end

  ```

  """

  use Prometheus.Erlang, :prometheus_gauge

  @doc """
  Creates a gauge using `spec`.

  Raises `Prometheus.MissingMetricSpecKeyError` if required `spec` key is missing.<br>
  Raises `Prometheus.InvalidMetricNameError` if metric name is invalid.<br>
  Raises `Prometheus.InvalidMetricHelpError` if help is invalid.<br>
  Raises `Prometheus.InvalidMetricLabelsError` if labels isn't a list.<br>
  Raises `Prometheus.InvalidMetricNameError` if label name is invalid.<br>
  Raises `Prometheus.InvalidValueError` exception if duration_unit is unknown or
  doesn't match metric name.<br>
  Raises `Prometheus.MFAlreadyExistsError` if a gauge with the same `spec` exists.
  """
  defmacro new(spec) do
    Erlang.call([spec])
  end

  @doc """
  Creates a gauge using `spec`.
  If a gauge with the same `spec` exists returns `false`.

  Raises `Prometheus.MissingMetricSpecKeyError` if required `spec` key is missing.<br>
  Raises `Prometheus.InvalidMetricNameError` if metric name is invalid.<br>
  Raises `Prometheus.InvalidMetricHelpError` if help is invalid.<br>
  Raises `Prometheus.InvalidMetricLabelsError` if labels isn't a list.<br>
  Raises `Prometheus.InvalidMetricNameError` if label name is invalid.<br>
  Raises `Prometheus.InvalidValueError` exception if duration_unit is unknown or
  doesn't match metric name.
  """
  defmacro declare(spec) do
    Erlang.call([spec])
  end

  @doc """
  Sets the gauge identified by `spec` to `value`.

  Raises `Prometheus.InvalidValueError` exception if `value` isn't
  a number or `:undefined`.<br>
  Raises `Prometheus.UnknownMetricError` exception if a gauge for `spec`
  can't be found.<br>
  Raises `Prometheus.InvalidMetricArityError` exception if labels count mismatch.
  """
  defmacro set(spec, value) do
    Erlang.metric_call(spec, [value])
  end

  @doc """
  Increments the gauge identified by `spec` by `value`.

  Raises `Prometheus.InvalidValueError` exception if `value` isn't an integer.<br>
  Raises `Prometheus.UnknownMetricError` exception if a gauge for `spec`
  can't be found.<br>
  Raises `Prometheus.InvalidMetricArityError` exception if labels count mismatch.
  """
  defmacro inc(spec, value \\ 1) do
    Erlang.metric_call(spec, [value])
  end

  @doc """
  Decrements the gauge identified by `spec` by `value`.

  Raises `Prometheus.InvalidValueError` exception if `value` isn't an integer.<br>
  Raises `Prometheus.UnknownMetricError` exception if a gauge for `spec`
  can't be found.<br>
  Raises `Prometheus.InvalidMetricArityError` exception if labels count mismatch.
  """
  defmacro dec(spec, value \\ 1) do
    Erlang.metric_call(spec, [value])
  end

  @doc """
  Increments the gauge identified by `spec` by `value`.
  If `value` happened to be a float number even one time(!) you shouldn't
  use `inc/2` or `dec/2` after dinc.

  Raises `Prometheus.InvalidValueError` exception if `value` isn't a number.<br>
  Raises `Prometheus.UnknownMetricError` exception if a gauge
  for `spec` can't be found.<br>
  Raises `Prometheus.InvalidMetricArityError` exception if labels count mismatch.
  """
  defmacro dinc(spec, value \\ 1) do
    Erlang.metric_call(spec, [value])
  end

  @doc """
  Decrements the gauge identified by `spec` by `value`.
  If `value` happened to be a float number even one time(!) you shouldn't
  use `inc/2` or `dec/2` after ddec.

  Raises `Prometheus.InvalidValueError` exception if `value` isn't a number.<br>
  Raises `Prometheus.UnknownMetricError` exception if a gauge
  for `spec` can't be found.<br>
  Raises `Prometheus.InvalidMetricArityError` exception if labels count mismatch.
  """
  defmacro ddec(spec, value \\ 1) do
    Erlang.metric_call(spec, [value])
  end

  @doc """
  Sets the gauge identified by `spec` to the current unixtime.

  Raises `Prometheus.UnknownMetricError` exception if a gauge
  for `spec` can't be found.<br>
  Raises `Prometheus.InvalidMetricArityError` exception if labels count mismatch.
  """
  defmacro set_to_current_time(spec) do
    Erlang.metric_call(spec)
  end

  @doc """
  Sets the gauge identified by `spec` to the number of currently executing `fun`s.

  Raises `Prometheus.UnknownMetricError` exception if a gauge
  for `spec` can't be found.<br>
  Raises `Prometheus.InvalidMetricArityError` exception if labels count mismatch.
  Raises `Prometheus.InvalidValueError` exception if fun isn't a function or block.
  """
  defmacro track_inprogress(spec, fun) do
    Erlang.metric_call(spec, [Erlang.ensure_fn(fun)])
  end

  defmacro track_inprogress(spec) do
    quote do
      @instrument {unquote(__MODULE__), :track_inprogress, unquote(spec)}
    end
  end

  @doc """
  Tracks the amount of time spent executing `fun`.

  Raises `Prometheus.UnknownMetricError` exception if a gauge
  for `spec` can't be found.<br>
  Raises `Prometheus.InvalidMetricArityError` exception if labels count mismatch.
  Raises `Prometheus.InvalidValueError` exception if `fun` isn't a function or block.
  """
  defmacro set_duration(spec, fun) do
    Erlang.metric_call(spec, [Erlang.ensure_fn(fun)])
  end

  @doc """
  Removes gauge series identified by spec.

  Raises `Prometheus.UnknownMetricError` exception if a gauge
  for `spec` can't be found.<br>
  Raises `Prometheus.InvalidMetricArityError` exception if labels count mismatch.
  """
  defmacro remove(spec) do
    Erlang.metric_call(spec)
  end

  @doc """
  Resets the value of the gauge identified by `spec`.

  Raises `Prometheus.UnknownMetricError` exception if a gauge
  for `spec` can't be found.<br>
  Raises `Prometheus.InvalidMetricArityError` exception if labels count mismatch.
  """
  defmacro reset(spec) do
    Erlang.metric_call(spec)
  end

  @doc """
  Returns the value of the gauge identified by `spec`.

  If duration unit set, value will be converted to the duration unit.
  [Read more here.](time.html)

  Raises `Prometheus.UnknownMetricError` exception if a gauge
  for `spec` can't be found.<br>
  Raises `Prometheus.InvalidMetricArityError` exception if labels count mismatch.
  """
  defmacro value(spec) do
    Erlang.metric_call(spec)
  end
end

