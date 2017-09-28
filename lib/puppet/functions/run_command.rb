# Runs a command on the given set of nodes and returns the result from each command execution.
#
# * This function does nothing if the list of nodes is empty.
# * It is possible to run on the node 'localhost'
# * A node is a String with a node's hostname or a URI that also describes how to connect and run the task on that node
#   including "user" and "password" parts of a URI.
# * The returned value contains information about the result per node. TODO: needs mapping to a runtime Pcore Object to be useful
#
#
# Since > 5.4.0 TODO: Update when version is known
#
Puppet::Functions.create_function(:run_command) do
  local_types do
    type 'NodeOrNodes = Variant[String[1], Array[NodeOrNodes]]'
  end

  dispatch :run_command do
    param 'String[1]', :command
    repeated_param 'NodeOrNodes', :nodes
  end

  def run_command(command, *nodes)
    unless Puppet[:tasks]
      raise Puppet::ParseErrorWithIssue.from_issue_and_stack(
        Puppet::Pops::Issues::TASK_OPERATION_NOT_SUPPORTED_WHEN_COMPILING,
        {:operation => 'run_command'})
    end

    unless Puppet.features.bolt?
      raise Puppet::ParseErrorWithIssue.from_issue_and_stack(Puppet::Pops::Issues::TASK_MISSING_BOLT, :action => _('run a command'))
    end

    hosts = nodes.flatten
    if hosts.empty?
      call_function('debug', "Simulating run_command('#{command}') - no hosts given - no action taken")
      []
    else
      # TODO, rewrite once proper handling of returned values is fully specified
      Bolt::Executor.from_uris(hosts).run_command(command).map do |_, result|
        result.success? ? result.output_string : result.exit_code
      end
    end
  end
end
