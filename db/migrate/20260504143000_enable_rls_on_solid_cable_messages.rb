class EnableRlsOnSolidCableMessages < ActiveRecord::Migration[8.0]
  def up
    return unless table_exists?(:solid_cable_messages)

    execute <<~SQL
      ALTER TABLE public.solid_cable_messages ENABLE ROW LEVEL SECURITY;
    SQL
  end

  def down
    return unless table_exists?(:solid_cable_messages)

    execute <<~SQL
      ALTER TABLE public.solid_cable_messages DISABLE ROW LEVEL SECURITY;
    SQL
  end
end
